# RustDeskX

RustDeskX 是面向 Apple Silicon Mac 的 RustDesk 个人重品牌发行包：

- 应用名称：`RustDeskX`
- Bundle ID：`com.omzcj.rustdeskx`
- 主执行文件：`RustDeskX`
- 架构：仅 `arm64`
- 发行：Developer ID 签名并经 Apple 公证
- 上游版本：RustDesk 1.4.9

本仓库不修改 RustDesk 的远程桌面协议或绕过任何安全机制。构建流程固定校验官方 arm64 DMG 的 SHA-256，然后修改应用包元数据并完整重签。

## 安装

发布首版后可通过 Homebrew 安装：

```bash
brew tap omzcj/omzcj
brew install --cask rustdeskx
```

也可以从 Releases 下载 `RustDeskX-<version>-arm64.zip`，解压后拖入“应用程序”。

## 首次配置

1. 在“系统设置 → 隐私与安全性”中为 RustDeskX开启“屏幕与系统录音”和“辅助功能”；系统提示时再开启“输入监控”。
2. RustDeskX → 设置 → 常规：开启硬件加速。
3. RustDeskX → 设置 → 安全：设置固定密码，并开启“允许 IP 直接访问”。
4. 手机、控制端和被控 Mac 登录同一 Tailscale。
5. 使用 `<Tailscale IP 或 MagicDNS 名称>:21118` 连接。

不需要把 21118 端口暴露到公网。Tailscale 显示 `direct` 时通常延迟最低；`peer-relay` 或 DERP 中继仍可能增加延迟。

更完整的 Tailscale、无人值守与权限说明见 [USAGE.md](USAGE.md)。

## 本地验证构建

```bash
CODE_SIGN_IDENTITY=- Scripts/package-release.sh
```

正式发行由 `v1.4.9.2` 形式的标签触发 GitHub Actions，完成 Developer ID 签名、公证和 Release。

## 上游与许可

RustDesk 由 RustDesk 项目维护，并依据 GPL-3.0 发布。本仓库保留上游版权与许可信息；详情见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。RustDeskX 与 RustDesk 官方项目没有隶属或背书关系。
