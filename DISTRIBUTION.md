# 发行说明

## 版本

`Config/upstream.env` 保存上游版本、arm64 DMG SHA-256 与 RustDeskX 修订号。发行版本格式为：

```text
<RustDesk 上游版本>.<RustDeskX 修订号>
```

例如 `1.4.9.3`，Git 标签为 `v1.4.9.3`。App 的
`CFBundleShortVersionString` 保持上游版本 `1.4.9`；`CFBundleVersion` 使用
`<上游 Build>.<RustDeskX 修订号>`，例如 `67.3`，从 App 内即可区分同一上游版本的
不同重打包。

## Actions Secrets 与 Match

- `APPLE_ASC_KEY_ID`
- `APPLE_ASC_ISSUER_ID`
- `APPLE_ASC_PRIVATE_KEY_BASE64`
- `APPLE_MATCH_PASSWORD`
- `APPLE_MATCH_GIT_PRIVATE_KEY`

CI 通过只读 Fastlane Match 恢复 Developer ID 身份。不得把密码、P12、P8、私钥、
provisioning profile 或解码文件提交到仓库、写入工作流或上传为普通 Artifact。
凭证轮换和 Match 写入遵循 `assassinor/apple-ci` 的 credential runbook；普通发布不得
启用 Match 写入。

## 发布流程

1. 更新并验证 `Config/upstream.env`。
2. 推送主分支并等待 CI 成功。
3. 创建并推送与配置一致的签名标签，例如
   `git tag -s v1.4.9.3 -m "RustDeskX 1.4.9.3"`。
4. Release 工作流下载并校验上游 DMG，重品牌、签名、公证和发布 ZIP。
5. 用 Release ZIP 的 SHA-256 更新 `homebrew-omzcj/Casks/rustdeskx.rb`。
