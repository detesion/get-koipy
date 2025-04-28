#!/usr/bin/env bash
# -*- coding: utf-8 -*-

# 必须以 root 权限运行
if [[ $EUID -ne 0 ]]; then
    echo "错误：本脚本需要 root 权限执行。" >&2
    exit 1
fi

# 全局变量
container_name=""

setup_environment() {
    if [ ! -d "./koipy" ]; then
        mkdir -p ./koipy
        echo "创建了 koipy 文件夹。"
    fi

    wget -O ./koipy/config.yaml https://raw.githubusercontent.com/detesion/get-koipy/refs/heads/main/config.example.yaml
    echo "下载 config.yaml 文件。"
}

welcome() {
    echo
    echo "安装即将开始"
    echo "如果您想取消安装，请在 5 秒内按 Ctrl+C 终止脚本。"
    echo
    sleep 5
}

docker_check() {
    echo "正在检查 Docker 安装情况 . . ."
    if ! command -v docker &>/dev/null; then
        echo "Docker 未安装，请安装 Docker 并将当前用户加入 docker 组。"
        exit 1
    fi
    echo "Docker 已安装。"
}

access_check() {
    echo "测试 Docker 权限 . . ."
    if [ -w /var/run/docker.sock ]; then
        echo "当前用户有权访问 Docker。"
    else
        echo "当前用户无权访问 Docker 或 Docker 未运行，请检查。"
        exit 1
    fi
}

build_docker() {
    read -r -p "请输入容器名称：" container_name
    echo "正在拉取 Docker 镜像 . . ."
    docker rm -f "$container_name" &>/dev/null || true
    docker pull koipy/koipy:latest
}

configure_bot() {
    echo "请确保当前目录下有 koipy 文件夹。"
    if [ ! -d "./koipy" ]; then
        echo "缺少 koipy 文件夹，退出。"
        exit 1
    fi

    if [ ! -f "./koipy/config.yaml" ]; then
        echo "缺少 config.yaml 文件，退出。"
        exit 1
    fi

    echo "开始配置参数 . . ."
    read -r -p "请输入 License: " license
    read -r -p "请输入 Bot Token: " bot_token
    read -r -p "请输入 API ID: " api_id
    read -r -p "请输入 API Hash: " api_hash
    read -r -p "请输入代理地址(默认不使用): " proxy
    read -r -p "请输入 HTTP 代理地址(默认不使用): " http_proxy
    read -r -p "请输入 SOCKS5 代理地址(默认不使用): " socks5_proxy
    read -r -p "请输入 Slave ID: " slave_id
    read -r -p "请输入 Slave Token: " slave_token
    read -r -p "请输入 Slave Address(默认127.0.0.1:8765): " slave_address
    slave_address=${slave_address:-"127.0.0.1:8765"}
    read -r -p "请输入 Slave Path(默认/): " slave_path
    slave_path=${slave_path:-"/"}
    read -r -p "请输入 Slave Comment: " slave_comment
    read -r -p "是否启用 Sub-Store (默认false): " substore_enable
    substore_enable=${substore_enable:-"false"}
    read -r -p "是否自动部署 Sub-Store (默认false): " substore_autoDeploy
    substore_autoDeploy=${substore_autoDeploy:-"false"}

    # 更新 config.yaml
    sed -i.bak \
        -e "s|^license: .*|license: $license|" \
        -e "s|^\(  bot-token: \).*|\1$bot_token|" \
        -e "s|^\(  api-id: \).*|\1\"$api_id\"|" \
        -e "s|^\(  api-hash: \).*|\1$api_hash|" \
        -e "s|^\(  proxy: \).*|\1$proxy|" \
        -e "s|^\(  httpProxy: \).*|\1$http_proxy|" \
        -e "s|^\(  socks5Proxy: \).*|\1$socks5_proxy|" \
        -e "s|^\(      id: \).*|\1\"$slave_id\"|" \
        -e "s|^\(      token: \).*|\1'$slave_token'|" \
        -e "s|^\(      address: \).*|\1\"$slave_address\"|" \
        -e "s|^\(      path: \).*|\1$slave_path|" \
        -e "s|^\(      comment: \).*|\1\"$slave_comment\"|" \
        ./koipy/config.yaml

    # 处理 substore
    if grep -q "substore:" ./koipy/config.yaml; then
        sed -i.bak "/substore:/,/^ *[^ ]/ {
            /^ *enable:/ s|: .*|: $substore_enable|
            /^ *autoDeploy:/ s|: .*|: $substore_autoDeploy|
        }" ./koipy/config.yaml
    else
        cat <<EOF >> ./koipy/config.yaml

substore:
  enable: $substore_enable
  autoDeploy: $substore_autoDeploy
EOF
    fi

    echo "config.yaml 已更新。"
}

start_docker() {
    echo "正在启动 Docker 容器 . . ."
    docker run -dit --restart=no --name="$container_name" --hostname="$container_name" \
        -v "$(pwd)/koipy/config.yaml:/app/config.yaml" \
        --network host koipy/koipy:latest
    echo
    echo "Docker 容器 $container_name 已启动。"
}

start_installation() {
    setup_environment
    welcome
    docker_check
    access_check
    build_docker
    configure_bot
    start_docker
}

cleanup() {
    read -r -p "请输入容器名称：" container_name
    echo "开始删除 Docker 容器 . . ."
    if docker inspect "$container_name" &>/dev/null; then
        docker rm -f "$container_name" &>/dev/null
        echo "容器 $container_name 已删除。"
    else
        echo "容器 $container_name 不存在。"
    fi
    echo
    show_online
}

stop_koipy() {
    read -r -p "请输入容器名称：" container_name
    echo "正在停止 Docker 容器 . . ."
    if docker inspect "$container_name" &>/dev/null; then
        docker stop "$container_name" &>/dev/null
        echo "容器 $container_name 已停止。"
    else
        echo "容器 $container_name 不存在。"
    fi
    echo
    show_online
}

start_koipy() {
    read -r -p "请输入容器名称：" container_name
    echo "正在启动 Docker 容器 . . ."
    if docker inspect "$container_name" &>/dev/null; then
        docker start "$container_name" &>/dev/null
        echo "容器 $container_name 已启动。"
    else
        echo "容器 $container_name 不存在。"
    fi
    echo
    show_online
}

restart_koipy() {
    read -r -p "请输入容器名称：" container_name
    echo "正在重新启动 Docker 容器 . . ."
    if docker inspect "$container_name" &>/dev/null; then
        docker restart "$container_name" &>/dev/null
        echo "容器 $container_name 已重新启动。"
    else
        echo "容器 $container_name 不存在。"
    fi
    echo
    show_online
}

reinstall_koipy() {
    cleanup
    build_docker
    start_docker
}

show_online() {
    echo
    echo "一键脚本出现任何问题请转手动搭建，我爱莫能助。"
    echo
    echo "欢迎使用 Koipy Docker 一键安装脚本。"
    echo
    echo "请选择需要进行的操作:"
    echo "  1) 安装 Koipy"
    echo "  2) 卸载 Koipy"
    echo "  3) 停止 Koipy"
    echo "  4) 启动 Koipy"
    echo "  5) 重启 Koipy"
    echo "  6) 重装 Koipy"
    echo "  7) 退出脚本"
    echo
    echo "Version：1.0.0"
    echo
    read -r -p "请输入编号: " N
    case $N in
        1) start_installation ;;
        2) cleanup ;;
        3) stop_koipy ;;
        4) start_koipy ;;
        5) restart_koipy ;;
        6) reinstall_koipy ;;
        7) exit 0 ;;
        *) echo "输入错误，请重新选择。" ; sleep 2; show_online ;;
    esac
}

# 启动菜单
show_online
