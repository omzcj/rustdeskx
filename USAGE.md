# RustDeskX 使用说明

## 推荐网络结构

```text
手机或控制电脑 ── Tailscale ── 被控 Mac 上的 RustDeskX:21118
```

所有设备登录同一个 Tailnet 后，可以直接使用 Tailscale IP：

```text
100.x.y.z:21118
```

也可以使用 MagicDNS：

```text
mac-name:21118
mac-name.your-tailnet.ts.net:21118
```

必须显式填写 `:21118`，否则名称可能被当作 RustDesk ID。

## macOS 权限

在“系统设置 → 隐私与安全性”中为 RustDeskX 开启：

- 屏幕与系统录音
- 辅助功能
- 输入监控（系统提示时）

Bundle ID 与官方 RustDesk 不同，因此官方应用原有权限不会继承。修改权限后应完全退出并重新打开 RustDeskX。

## RustDeskX 设置

- 常规：开启硬件加速或硬件编解码。
- 安全：使用固定强密码。
- 安全：开启“允许 IP 直接访问”。
- 账户 2FA 属于 RustDesk Server Pro；仅使用 Tailscale + Direct IP 时，访问控制来自 Tailscale 身份/ACL 与 RustDeskX 固定密码。

## 无人值守

无人值守表示被控设备无人确认时，仍可通过固定密码建立远程会话。需要满足：

- RustDeskX 正在运行，或已正确配置登录启动/后台服务。
- 固定密码已启用。
- macOS 的屏幕录制和辅助功能权限已授予。
- 被控 Mac 未关机，并能通过 Tailscale 到达。

当前发行包修改的是官方已编译 arm64 应用的包元数据。主程序与 Direct IP 功能可独立使用，但上游二进制内部仍可能保留 RustDesk 服务名、安装路径和更新逻辑；对登录窗口控制、系统级后台服务或官方自动更新有强需求时，应改用完整源码白标构建。

## 连通性排查

```bash
tailscale ping <设备名或 IP>
tailscale status
lsof -nP -iTCP:21118 -sTCP:LISTEN
```

- `direct`：设备点对点直连。
- `peer-relay`：经过 Tailscale Peer Relay。
- `relay`：经过 DERP。

若 Tailscale 已是 `direct`，自建 RustDesk Server通常不会明显降低 Direct IP 会话延迟；卡顿更可能来自网络质量、编码性能、分辨率或被控端负载。

