# nb 容器

这个配置通过 Docker 使用 [nb](https://github.com/xwmx/nb) 命令行笔记工具，笔记
文件保存在 Windows 主机上。

## 前置条件

- 已安装并运行 [Docker Desktop](https://www.docker.com/products/docker-desktop/)。

## 使用方法

### 1. 构建镜像

```powershell
docker compose build
```

### 2. 运行 nb

可以通过 Docker Compose 执行 `nb` 命令：

```powershell
docker compose run --rm nb help
```

### 3. 创建笔记

```powershell
docker compose run --rm nb add "Hello from Windows"
```

## 笔记存储

笔记和配置存储在当前目录下的 `./notes` 中，该目录会挂载到容器内的 `/root/.nb`。

- **全局可用**：由于挂载到了默认的 `~/.nb` 位置，`nb` 无论当前工作目录在哪里，
  都可以识别这些笔记。
- **Windows 访问**：可以直接在 Windows 中使用 VS Code 编辑 Markdown 文件，例如
  `notes/home/` 下的文件。

## 使用提示

如果希望更方便地使用 `nb`，可以在 PowerShell profile 中添加 alias 或函数：

```powershell
function nb { docker compose -f "D:\Workspace\configfiles\containers\nb-container\docker-compose.yml" run --rm nb $args }
```
