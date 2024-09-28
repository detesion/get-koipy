#!/usr/bin/env bash

if [[ $EUID -ne 0 ]]; then
    echo "错误：本脚本需要 root 权限执行。" 1>&2
    exit 1
fi

# 创建 koipy 文件夹并下载 config.yaml
setup_environment () {
    if [ ! -d "./koipy" ]; then
        mkdir -p ./koipy
        echo "创建了 koipy 文件夹。"
    fi

    wget -O ./koipy/config.yaml https://raw.githubusercontent.com/detesion/get-koipy/refs/heads/main/config.example.yaml
    echo "下载 config.yaml 文件。"
}

welcome () {
    echo
    echo "安装即将开始"
    echo "如果您想取消安装，"
    echo "请在 5 秒钟内按 Ctrl+C 终止此脚本。"
    echo
    sleep 5
}

docker_check () {
    echo "正在检查 Docker 安装情况 . . ."
    if command -v docker >> /dev/null 2>&1; then
        echo "Docker 已安装，继续安装过程 . . ."
    else
        echo "Docker 未安装在此系统上"
        echo "请安装 Docker 并将自己添加到 Docker 组，然后重新运行此脚本。"
        exit 1
    fi
}

access_check () {
    echo "测试 Docker 环境 . . ."
    if [ -w /var/run/docker.sock ]; then
        echo "当前用户可以使用 Docker,继续安装过程 . . ."
    else
        echo "当前用户无权访问 Docker,或者 Docker 没有运行。请添加自己到 Docker 组并重新运行此脚本。"
        exit 1
    fi
}

build_docker () {
    printf "请输入容器的名称："
    read -r container_name <&1
    echo "正在拉取 Docker 镜像 . . ."
    docker rm -f "$container_name" > /dev/null 2>&1
    docker pull koipy/koipy:latest
}

configure_bot () {
    echo "请确保当前目录下有 koipy 文件夹。"
    if [ -d "./koipy" ]; then
        # License 配置
        printf "请输入 License:"
        read -r license <&1

        # Bot 配置
        printf "请输入 Bot Token:"
        read -r bot_token <&1
        printf "请输入 API ID:"
        read -r api_id <&1
        printf "请输入 API Hash:"
        read -r api_hash <&1
        printf "请输入代理地址(默认不使用):"
        read -r proxy <&1
        #proxy=${proxy:-"socks5://127.0.0.1:11112"}

        # Network 配置
        printf "请输入 HTTP 代理地址(默认不使用):"
        read -r http_proxy <&1
        printf "请输入 SOCKS5 代理地址(默认不使用):"
        read -r socks5_proxy <&1
        #socks5_proxy=${socks5_proxy:-"socks5://127.0.0.1:1080"}

        # Slave Config 配置
        printf "请输入 Slave ID(后端id随便取):"
        read -r slave_id <&1
        printf "请输入 Slave Token(Miaospeed的连接token):"
        read -r slave_token <&1
        printf "请输入 Slave Address(默认127.0.0.1:8765):"
        read -r slave_address <&1
        slave_address=${slave_address:-"127.0.0.1:8765"}
        printf "请输入 Slave Path(默认/):"
        read -r slave_path <&1
        slave_path=${slave_path:-"/"}
        printf "请输入 Slave Comment(后端展示名):"
        read -r slave_comment <&1

        # 更新 config.yaml 文件
        if [[ -f "./koipy/config.yaml" ]]; then
            if grep -q "^license: " ./koipy/config.yaml; then
                sed -i.bak "s|^license: .*|license: $license|" ./koipy/config.yaml
            else
                echo "license: $license" >> ./koipy/config.yaml
            fi
            sed -i.bak "s|^\(  bot:\)|\1|" ./koipy/config.yaml
            sed -i.bak "s|^\(  bot-token: \).*|\1$bot_token|" ./koipy/config.yaml
            sed -i.bak "s|^\(  api-id: \).*|\1$api_id|" ./koipy/config.yaml
            sed -i.bak "s|^\(  api-hash: \).*|\1$api_hash|" ./koipy/config.yaml
            sed -i.bak "s|^\(  proxy: \).*|\1$proxy|" ./koipy/config.yaml
            sed -i.bak "s|^\(  httpProxy: \).*|\1$http_proxy|" ./koipy/config.yaml
            sed -i.bak "s|^\(  socks5Proxy: \).*|\1$socks5_proxy|" ./koipy/config.yaml
            sed -i.bak "s|^\(  slaveConfig:\)|\1|" ./koipy/config.yaml
            sed -i.bak "s|^\(    slave:\)|\1|" ./koipy/config.yaml
            sed -i.bak "s|^\(      id: \).*|\1\"$slave_id\"|" ./koipy/config.yaml
            sed -i.bak "s|^\(      token: \).*|\1\'$slave_token\'|" ./koipy/config.yaml
            sed -i.bak "s|^\(      address: \).*|\1\"$slave_address\"|" ./koipy/config.yaml
            sed -i.bak "s|^\(      path: \).*|\1$slave_path|" ./koipy/config.yaml
            sed -i.bak "s|^\(      comment: \).*|\1\"$slave_comment\"|" ./koipy/config.yaml
            echo "config.yaml 已更新。"
        else
            echo "缺少必要的配置文件，退出。"
            exit 1
        fi
    else
        echo "缺少必要的配置文件或目录，退出。"
        exit 1
    fi
}

start_docker () {
    echo "正在启动 Docker 容器 . . ."
    docker run -dit --restart=no --name="$container_name" --hostname="$container_name" \
        -v ./koipy/config.yaml:/app/config.yaml \
        --network host koipy/koipy:latest <&1
    echo
    echo "Docker 容器已启动。"
    echo
}

data_persistence () {
    echo "数据持久化可以在升级或重新部署容器时保留配置文件和数据。"
    printf "请确认是否进行数据持久化操作 [Y/n] :"
    read -r persistence <&1
    case $persistence in
        [yY][eE][sS] | [yY])
            echo "请确保当前目录下有 koipy 文件夹。"
            if [ -d "./koipy" ]; then
                echo "数据持久化操作完成。"
                echo
            else
                echo "缺少必要的配置文件或目录，退出。"
                exit 1
            fi
            ;;
        [nN][oO] | [nN])
            echo "结束。"
            ;;
        *)
            echo "输入错误 . . ."
            ;;
    esac
}

start_installation () {
    setup_environment  # 创建文件夹和配置文件
    welcome
    docker_check
    access_check
    build_docker
    configure_bot  # 调用配置 Bot Token 和 API 信息的函数
    start_docker
    data_persistence
}

cleanup () {
    printf "请输入容器的名称："
    read -r container_name <&1
    echo "开始删除 Docker 容器 . . ."
    if docker inspect "$container_name" &>/dev/null; then
        docker rm -f "$container_name" &>/dev/null
        echo "容器 $container_name 已删除。"
        echo
        show_online
    else
        echo "不存在名为 $container_name 的容器，退出。"
        exit 1
    fi
}

stop_koipy () {
    printf "请输入容器的名称："
    read -r container_name <&1
    echo "正在停止 Docker 容器 . . ."
    if docker inspect "$container_name" &>/dev/null; then
        docker stop "$container_name" &>/dev/null
        echo "容器 $container_name 已停止。"
        echo
        show_online
    else
        echo "不存在名为 $container_name 的容器，退出。"
        exit 1
    fi
}

start_koipy () {
    printf "请输入容器的名称："
    read -r container_name <&1
    echo "正在启动 Docker 容器 . . ."
    if docker inspect "$container_name" &>/dev/null; then
        docker start "$container_name" &>/dev/null
        echo "容器 $container_name 已启动。"
        echo
        show_online
    else
        echo "不存在名为 $container_name 的容器，退出。"
        exit 1
    fi
}

restart_koipy () {
    printf "请输入容器的名称："
    read -r container_name <&1
    echo "正在重新启动 Docker 容器 . . ."
    if docker inspect "$container_name" &>/dev/null; then
        docker restart "$container_name" &>/dev/null
        echo "容器 $container_name 已重新启动。"
        echo
        show_online
    else
        echo "不存在名为 $container_name 的容器，退出。"
        exit 1
    fi
}

reinstall_koipy () {
    cleanup
    build_docker
    start_docker
    data_persistence
}

show_online () {
    echo "一键脚本出现任何问题请转手动搭建,我爱莫能助"
    echo "一键脚本出现任何问题请转手动搭建,我爱莫能助"
    echo "一键脚本出现任何问题请转手动搭建,我爱莫能助"
    echo ""
    echo ""
    echo "欢迎使用 Koipy Docker 一键安装脚本。"
    echo
    echo "请选择您需要进行的操作:"
    echo "  1) 安装 Koipy"
    echo "  2) 卸载 Koipy"
    echo "  3) 停止 Koipy"
    echo "  4) 启动 Koipy"
    echo "  5) 重启 Koipy"
    echo "  6) 重装 Koipy"
    echo "  7) 退出脚本"
    echo
    echo "     Version：1.0.0"
    echo
    echo -n "请输入编号: "
    read -r N <&1
    case $N in
        1)
            start_installation
            ;;
        2)
            cleanup
            ;;
        3)
            stop_koipy
            ;;
        4)
            start_koipy
            ;;
        5)
            restart_koipy
            ;;
        6)
            reinstall_koipy
            ;;
        7)
            exit 0
            ;;
        *)
            echo "输入错误!"
            sleep 5s
            show_online
            ;;
    esac 
}

show_online
