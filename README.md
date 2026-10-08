# DSH Docker Image

用于运行 [DeepSeek Harness (DSH)](https://github.com/deepseek-ai/deepseek-harness) Web UI 的 Docker 镜像。

镜像包含：

- Node.js 22、npm、npx
- pnpm
- Python 3、pip、venv
- curl、wget、git
- `@deepseek-ai/dsh`

默认启动命令为：

```text
dsh web --no-open
```

## 本地构建

```bash
docker build -t dsh:local .
```

构建特定 DSH 版本：

```bash
docker build --build-arg DSH_VERSION=<version> -t dsh:<version> .
```

## 本地运行

DSH Web UI 默认只绑定到 `127.0.0.1:3080`。在 Linux Docker 主机上使用 host 网络运行：

```bash
docker run --rm -it --network host \
  -v "$PWD":/workspace \
  -v dsh-data:/root/.dsh \
  dsh:local
```

在 Docker 主机本机浏览器中打开：

```text
http://127.0.0.1:3080
```

`/workspace` 是工作目录，`/root/.dsh` 保存 DSH 配置和状态。

## GitHub 自动构建

[`.github/workflows/publish-image.yml`](.github/workflows/publish-image.yml) 会在以下情况构建并发布多架构镜像：

- 推送到 `main`
- 推送 `v*` 标签
- 在 GitHub Actions 页面手动运行

发布地址格式为：

```text
ghcr.io/<GitHub 用户名或组织>/<仓库名>:latest
```

首次发布后，在 GitHub 仓库的 Packages 设置中将镜像设为 Public，飞牛 NAS 才能无需登录直接拉取。若保持 Private，请先在飞牛 NAS 的 Docker 设置中登录 `ghcr.io`，并使用具有 `read:packages` 权限的 GitHub Personal Access Token。

> GitHub Actions 工作流必须位于 GitHub 仓库根目录的 `.github/workflows/` 下。

## 飞牛 NAS 部署

在飞牛 NAS 的 Docker Compose 中使用以下配置，并将镜像地址替换为自己的 GHCR 地址：

```yaml
services:
  dsh:
    image: ghcr.io/<owner>/<repository>:latest
    container_name: dsh
    network_mode: host
    restart: unless-stopped
    volumes:
      - /vol1/docker/dsh-data:/root/.dsh
      - /vol1/docker/dsh-workspace:/workspace
```

DSH 不会监听 NAS 的 LAN 地址。请从电脑建立 SSH 隧道：

```bash
ssh -L 3080:127.0.0.1:3080 <nas-user>@<nas-ip>
```

随后在电脑浏览器中打开：

```text
http://127.0.0.1:3080
```

不要使用 `-p 3080:3080` 将 DSH Web UI 直接公开到网络中。
