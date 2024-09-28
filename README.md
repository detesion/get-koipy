# koipy测速tgbot一键安装脚本

koipy是一个Telegram 节点测速、连通性测试机器人，同时提供对接miaospeed后端的开源实现。 koipy是fulltclash的下游分支。

## 功能特性

- 配置文件参数的配置
    * license
    * bot-token
    * api-id
    * api-hash
    * slaveConfig
    * ***etc.***

## 系统要求

经过测试支持**Docker version 20.10.23+**，其他版本未测试，理论支持所有docker版本

## 架构支持

x86_64 / AMD64，不滋瓷ARM架构

## 使用说明
* 为了顺利，顺畅地安装koipy首先需要准备以下信息：
		按照[https://koipy.gitbook.io/koipy/ji-huo](https://koipy.gitbook.io/koipy/ji-huo)提供的方法获取license备用
		去 @BotFather 那里创建一个机器人，获得该机器人的bot_token，应形如：bot_token = "123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11"
	**获取bot_token这步不会请Google。**

> 可选信息(optional)：
		⚠️koipy从1.2版本开始内置api_hash, api_id，你仅需要bot_token即可开始玩耍。当然你想用自己的api也可以。
	Telegram 的api_id 、api_hash 获取地址 不会请Google。(部分TG账号已被拉黑，无法正常使用，尝试更换代理IP，IP干净成功率高，用机场节点就自求多福吧🙃)
* 为了确保能正常install，请先安装基础组件`wget`、`curl`、`ca-certificates`，以 Debian 为例子：
```
apt install wget curl ca-certificates
```

* 下载并运行脚本
```
wget https://raw.githubusercontent.com/detesion/get-koipy/refs/heads/main/koipy-docker.sh -O koipy-docker.sh && chmod +x koipy-docker.sh && bash koipy-docker.sh
```





<p align="center"> 
  Visitor Count<br>
  <img src="https://profile-counter.glitch.me/detesion/count.svg" />
</p>
