# Surgio-Docker项目配置及简易食用教程
### 初版，如有发现编写错误和其他建议欢迎提issue

### 使用本仓库的前提条件

- 浏览[Surgio官方文档-快速搭建托管API](https://surgio.js.org/guide/advance/api-gateway.html#%E8%87%AA%E6%9C%89%E6%9C%8D%E5%8A%A1%E5%99%A8%E9%83%A8%E7%BD%B2)了解准备方法，并按教程准备好配置文件。

- 若自己不会准备，则可下载本库中的示例gateway.js（https://raw.githubusercontent.com/accors/surgio-docker/main/gateway.js
- 将该gateway.js放入你的Surgio文件夹根目录。

- 安装Docker与Docker-Compose。可使用curl -fsSL https://get.docker.com | bash -s docker 一键安装，运行完成后自行安装docker-compose-plugin即可完成Docker-Compose安装。

- 拉取Docker镜像：accors/surgio:latest 
  - 懒人命令：docker pull accors/surgio:latest
  
- 将自己的Surgio文件夹上传至私有Git存储库，并获取私钥（OPENSSH PRIVATE KEY开头）并自行转义换行以备用。

- 配置Docker-Compose配置文件，下附示例

``` yaml
version: '3.7'
services:
  surgio:
    image: accors/surgio:latest
    container_name: surgio-docker
    restart: unless-stopped
    environment:
      - REPO_URL=Git存储库链接（示例：git@github.com:用户名/仓库名称.git）
      - REPO-DOMAIN=存储库使用的域名（示例：github.com）
      - REPO-BRANCH=存储库的分支名称（示例：main）
      - KEY=存储库转义后的私钥
    ports:
      - "3000:3000" #默认gateway指定内部监听端口3000，若需修改则自己修改Surgio配置仓库中的gateway.js，并修改：后的端口号。
    volumes:
      - "./surgio:/surgio" #默认映射文件夹的根目录下surgio文件夹为主目录
```

- 启动容器。首先运行mkdir -p surgio-docker && cd surgio-docker建立文件夹，将自己修改后的Docker-Compose配置文件保存为docker-compose.yml在该文件夹下，运行docker-compose up -d即可自动启动容器。若更新了配置，则可重启容器进行配置应用。


### 特别感谢以下作者以及整合时参考的作者 
- [@geekdada](https://github.com/surgioproject/surgio)
- [@lowking](https://github.com/lowking/rule-store)

### 如果该项目对你使用有帮助，可以考虑点个*Star*, 感激不尽。
