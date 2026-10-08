# DSH Docker Image

用于通过 Docker 运行 DeepSeek Harness (DSH) Web UI。镜像固定安装
`@deepseek-ai/dsh@0.2.0-rc.2`，并内置 Node 反向代理，使 DSH 能通过 Docker
端口映射提供局域网访问。

## 镜像内容

- Node.js 24、npm、npx、pnpm
- Python 3、pip、venv
- `git`、`curl`、`wget`、`jq`、`nano`、`vim`、`tmux`、`htop`、`tree`
- `ssh` 客户端、`rsync`、`zip`、`unzip`、`ping`、`netcat`、`lsof`
- `build-essential`、`bash-completion` 等常用开发与排障工具

## 网络方式

DSH 保持在容器内的 `127.0.0.1:3079` 监听。内置 Node 代理监听
`0.0.0.0:3080` 并转发 HTTP 和 WebSocket 请求，因此可直接使用
`-p 3080:3080`。

代理还处理局域网访问所需的浏览器兼容与请求来源对齐，并可选启用 HTTP Basic Auth。

## 构建

```bash
docker build -t dsh:local .
```

默认 DSH 版本是 `0.2.0-rc.2`。如需覆盖：

```bash
docker build --build-arg DSH_VERSION=<version> -t dsh:<version> .
```

## 运行

```bash
docker run -d \
  --name dsh \
  -p 3080:3080 \
  -v dsh-data:/root/.dsh \
  -v "$PWD":/workspace \
  --restart unless-stopped \
  dsh:local
```

在浏览器访问：

```text
http://<Docker 主机 IP>:3080
```

`/root/.dsh` 保存 DSH 配置与状态，`/workspace` 是默认工作目录。

## Basic Auth

将下面两个环境变量同时传入即可保护 Web UI：

```bash
docker run -d \
  --name dsh \
  -p 3080:3080 \
  -v dsh-data:/root/.dsh \
  -e PROXY_USERNAME=<username> \
  -e PROXY_PASSWORD=<password> \
  --restart unless-stopped \
  dsh:local
```

不要在没有认证或网络访问控制的情况下，把 3080 转发到互联网。

## 端口配置

| Environment variable | Default | Description |
| --- | --- | --- |
| `DSH_PORT` | `3079` | DSH 在容器回环地址监听的端口 |
| `PROXY_PORT` | `3080` | Node 代理对外监听的端口 |
| `PROXY_USERNAME` | Unset | Basic Auth username |
| `PROXY_PASSWORD` | Unset | Basic Auth password |

`DSH_PORT` 和 `PROXY_PORT` 必须不同。若修改 `PROXY_PORT`，Docker 映射应同步修改，例如
`-e PROXY_PORT=3088 -p 3088:3088`。

## GitHub 自动构建

[`.github/workflows/publish-image.yml`](.github/workflows/publish-image.yml) 会在推送到
`main`、推送 `v*` 标签或手动触发时发布多架构镜像到：

```text
ghcr.io/<GitHub 用户名或组织>/<仓库名>:latest
```

首次发布后，在 GitHub Packages 设置镜像可见性为 Public；若保持 Private，请在 NAS
或 Docker 主机中使用具备 `read:packages` 权限的 GitHub token 登录 `ghcr.io`。
