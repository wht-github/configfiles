# Codex DeepSeek 配置

本目录维护 Codex 的 DeepSeek profile，配置同时适用于 Windows 与 Linux。

## 文件

- `deepseek.config.toml`：profile 配置，部署为 `~/.codex/deepseek.config.toml`。
- `models.json`：`deepseek-v4-flash` / `deepseek-v4-pro` 的模型目录，
  部署为 `~/.codex/models.json`，由 profile 中的 `model_catalog_json` 引用。

## 前置条件

- Codex CLI 0.134.0 或更新版本（0.134.0 起 profile 使用独立文件，不再读取
  `[profiles.<name>]` 内联段）。
- 环境变量 `DEEPSEEK_API_KEY` 已设置，且指向有效的 DeepSeek API key。

## 安装

部署前先备份 `~/.codex` 下已有的同名文件，再复制新配置。

### Windows

```powershell
$codexDir = Join-Path $env:USERPROFILE '.codex'
$stamp = Get-Date -Format yyyyMMdd-HHmmss
foreach ($name in @('deepseek.config.toml', 'models.json')) {
    $source = Join-Path .\codex $name
    $dest = Join-Path $codexDir $name
    if (Test-Path -LiteralPath $dest) {
        Copy-Item -LiteralPath $dest "$dest.bak-$stamp"
    }
    Copy-Item -LiteralPath $source -Destination $dest -Force
}
```

API key 由用户自行配置为环境变量。仓库和 profile 都不保存、不注入 token，Codex
只从环境中读取 `DEEPSEEK_API_KEY`。设置为用户级环境变量后重新启动终端：

```powershell
[Environment]::SetEnvironmentVariable('DEEPSEEK_API_KEY', '<your-token>', 'User')
```

### Linux

```bash
CODEX_PROFILE_DIR="$HOME/.codex"
mkdir -p "$CODEX_PROFILE_DIR"
stamp="$(date +%Y%m%d-%H%M%S)"
for f in deepseek.config.toml models.json; do
    if [ -f "$CODEX_PROFILE_DIR/$f" ]; then
        cp "$CODEX_PROFILE_DIR/$f" "$CODEX_PROFILE_DIR/$f.bak-$stamp"
    fi
    cp "codex/$f" "$CODEX_PROFILE_DIR/$f"
done
```

把 API key 写入 shell 登录配置，例如：

```bash
printf '\nexport DEEPSEEK_API_KEY="%s"\n' '<your-token>' >> ~/.profile
```

## 使用

```bash
codex --profile deepseek
codex exec --profile deepseek "review this change"
```

## 注意事项

- `model_catalog_json = "~/.codex/models.json"` 依赖 `~` 展开；如果自定义了
  `CODEX_HOME`，请把该值改成实际的绝对路径。
- profile 使用顶层 key（Codex 0.134.0+ 的格式），不要在文件里使用
  `[profiles.deepseek]` 内联段。
- `[projects]` trust 条目、API key 等机器相关内容不属于本目录，每台机器
  自行维护在用户级配置中。

官方参考：[Advanced Configuration](https://learn.chatgpt.com/docs/config-file/config-advanced)
与 [Configuration Reference](https://learn.chatgpt.com/docs/config-file/config-reference)。
