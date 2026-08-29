# 发行说明

## 版本

`Config/upstream.env` 保存上游版本、arm64 DMG SHA-256 与 RustDeskX 修订号。发行版本格式为：

```text
<RustDesk 上游版本>.<RustDeskX 修订号>
```

例如 `1.4.9.1`，Git 标签为 `v1.4.9.1`。

## Actions Secrets

- `DEVELOPER_ID_P12_BASE64`：P12 的 Base64。
- `APP_STORE_CONNECT_API_PRIVATE_KEY_BASE64`
- `APP_STORE_CONNECT_API_KEY_ID`
- `APP_STORE_CONNECT_API_ISSUER_ID`

Apple 的 `security import` 无法可靠导入真正空密码的 OpenSSL 3 PKCS#12，因此 P12 使用固定兼容口令 `rustdeskx`，不再单独保存密码 Secret。该口令不是安全边界；真正的保护来自 GitHub Actions Secret。P12 文件一旦单独泄漏即可直接使用，因此不得把 P12、私钥或解码文件提交到仓库或上传为普通 Artifact。

## 发布流程

1. 更新并验证 `Config/upstream.env`。
2. 推送主分支并等待 CI 成功。
3. 创建并推送与配置一致的带注释标签。
4. Release 工作流下载并校验上游 DMG，重品牌、签名、公证和发布 ZIP。
5. 用 Release ZIP 的 SHA-256 更新 `homebrew-omzcj/Casks/rustdeskx.rb`。
