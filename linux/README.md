# Linux 配置

本目录维护 Linux 环境（bash）的配置，与 Windows 侧的 `pwsh/` 对应。

## 文件

- `bashrc.d/10-mouse.conf`：部署为 `~/.bashrc.d/10-mouse.conf`，定义 `mouseoff`
  alias（执行 `printf '\e[?1000l'` 关闭终端鼠标点击上报）。

## 前置条件

- `~/.bashrc` 已包含 `~/.bashrc.d` 的 source 循环（本仓库默认的
  `.bashrc` 片段已带）。若没有，先添加：

```bash
if [ -d ~/.bashrc.d ]; then
    for rc in ~/.bashrc.d/*; do
        [ -f "$rc" ] && . "$rc"
    done
fi
```

## 安装

```bash
mkdir -p ~/.bashrc.d
cp linux/bashrc.d/*.conf ~/.bashrc.d/
. ~/.bashrc
```

## 使用

```bash
mouseoff   # 关闭鼠标点击上报
```
