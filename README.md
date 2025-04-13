# Docker Auto Build

这是一个基于GitHub Actions的自动化Docker镜像构建工具。它可以自动从指定的代码仓库拉取代码，使用预定义的Dockerfile构建镜像，并将镜像推送到DockerHub。

## 功能特点

- 支持多个代码仓库的自动化构建
- 支持自定义Dockerfile路径
- 支持构建参数配置
- 支持多平台构建（linux/amd64, linux/arm64）
- 自动标记最新版本和日期版本

## 配置说明

在`config.yaml`文件中配置需要构建的代码仓库信息：

```yaml
repositories:
  - name: example-service-1  # 服务名称
    repo_url: https://github.com/username/example-service-1  # 代码仓库地址
    branch: main  # 构建分支
    dockerfile: ./dockerfiles/example-service-1/Dockerfile  # Dockerfile路径
    image_name: username/example-service-1  # DockerHub镜像名称
    build_args:  # 构建参数（可选）
      ARG1: value1
      ARG2: value2
```

## 使用方法

1. Fork 本仓库
2. 在GitHub仓库设置中添加以下secrets：
   - `DOCKERHUB_USERNAME`: DockerHub用户名
   - `DOCKERHUB_TOKEN`: DockerHub访问令牌
3. 修改`config.yaml`文件，添加需要构建的代码仓库信息
4. 在`dockerfiles`目录下添加对应服务的Dockerfile
5. 提交更改到main分支，GitHub Actions将自动触发构建

## 自动构建触发条件

- 当`config.yaml`文件发生变更时
- 当`dockerfiles`目录下的文件发生变更时
- 手动触发工作流程

## 注意事项

- 确保DockerHub访问令牌具有推送镜像的权限
- 确保代码仓库地址和分支配置正确
- Dockerfile路径必须相对于代码仓库根目录
