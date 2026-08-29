# 发行说明

## 版本

`Config/upstream.env` 保存上游版本、arm64 DMG SHA-256 与 RustDeskX 修订号。发行版本格式为：

```text
<RustDesk 上游版本>.<RustDeskX 修订号>
```

例如 `1.4.9.2`，Git 标签为 `v1.4.9.2`。

## Actions Secrets

- `DEVELOPER_ID_P12_BASE64`：P12 的 Base64。
- `DEVELOPER_ID_P12_PASSWORD`：导出 P12 时设置的密码。
- `APP_STORE_CONNECT_API_PRIVATE_KEY_BASE64`
- `APP_STORE_CONNECT_API_KEY_ID`
- `APP_STORE_CONNECT_API_ISSUER_ID`

P12 必须使用由证书持有人本人设置的非空密码，并分别保存 P12 Base64 与密码两个 GitHub Actions Secret。不得把密码、P12、私钥或解码文件提交到仓库、写入工作流或上传为普通 Artifact。

## 发布流程

1. 更新并验证 `Config/upstream.env`。
2. 推送主分支并等待 CI 成功。
3. 创建并推送与配置一致的带注释标签。
4. Release 工作流下载并校验上游 DMG，重品牌、签名、公证和发布 ZIP。
5. 用 Release ZIP 的 SHA-256 更新 `homebrew-omzcj/Casks/rustdeskx.rb`。
