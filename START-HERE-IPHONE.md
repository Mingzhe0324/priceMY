# Windows → PriceMY → AltStore → iPhone

This package now includes `.github/workflows/ios-altstore.yml`.
这是**加入云端构建配置的源码包**，还不是 IPA。本次没有在 GitHub 或 Mac 上运行这个 workflow；成功编译后才会产生可交给 AltStore 签名的 IPA。若构建失败，请提供具体错误日志，不要跳过测试或把源码 ZIP 改名成 IPA。

## 1. 解压与上传（Windows）

1. 下载本次更新后的 ZIP，右键 → Extract All / 全部解压缩。
2. 打开解压出来的 `PriceMY` 文件夹。里面应直接看到 `.github`、`apps`、`backend`、`README.md`。
3. 浏览器登录 https://github.com ，右上角 + → New repository。
4. 名称填写 `PriceMY`，选 **Private**，勾选 Add a README file，点 Create repository。
5. 在仓库 Code 页，Add file → Upload files。
6. 在 Windows 中进入 PriceMY 文件夹，选中**里面的所有文件和文件夹**，拖到上传框。不要只上传 ZIP，也不要把外层 PriceMY 文件夹再套一层。
7. 确认上传列表包含 `.github/workflows/ios-altstore.yml`；点 Commit changes。
8. 上传完成后仓库根目录必须直接看到 `apps` 和 `.github`。点击 `.github` → `workflows`，确认有 `ios-altstore.yml`。

如果浏览器没有上传 `.github`：
- 仓库 Code → Add file → Create new file。
- 文件名输入 `.github/workflows/ios-altstore.yml`。
- 用 Windows 记事本打开本地同名文件，复制全部内容到 GitHub 编辑器，然后 Commit changes 到 main。
- 文件末尾必须是 `.yml`，不要保存成 `.yml.txt`。

只使用私有仓库来保护尚未发布的源码。本流程没有自动推送、创建仓库或替你消费构建额度。运行 GitHub Actions 会使用账号的 Actions 额度；如提示付款或额度不足，先检查账号设置，再决定是否继续。

## 2. 让云端 Mac 生成 IPA

1. 点击仓库顶部 **Actions**。
2. 若显示启用 Actions 的提示，启用此仓库的 workflows。
3. 左边选择 **Build iPhone IPA (AltStore)**。
4. 右侧 **Run workflow** → Branch 选 `main` → 再点绿色 **Run workflow**。
5. 刷新页面，打开新出现的任务。第一次需下载 Flutter 和依赖，等待任务完成；不要反复点击 Run。
6. 绿色勾表示整个流程成功。黄色表示仍在运行；红色表示失败。
7. 成功后打开该次运行的 Summary，下拉到 **Artifacts**，点击 **PriceMY-AltStore-IPA** 下载。必须登录有访问权限的 GitHub 账号。
8. 下载的通常是外层 ZIP。解压**外层 ZIP**，取得里面的 `PriceMY-unsigned.ipa`。
9. 保留 `.ipa` 后缀，不要继续解压 IPA 本身。旁边 `.sha256` 只是校验文件，不用导入 AltStore。

这个 workflow 使用 macOS runner 的 Xcode，运行依赖解析、Dart 分析、Flutter 测试及 iPhone 真机 release build（非模拟器），然后打包 `Payload/Runner.app`。**没有 Apple ID、密码、证书或付费开发者会员 secrets。** AltStore 会在你的 Windows/iPhone 环境完成签名。

若没有 Run workflow：检查文件是否在默认分支、路径是否在仓库根目录 `.github/workflows/`，以及仓库 Actions 是否启用。
若构建红色：打开失败的步骤，复制第一处 `Error` 附近的文字或截图给我。当前最重要的 gate 是 Analyze Dart / Run Flutter tests / Build physical-device release。上传截图前遮住个人信息。

## 3. 准备 AltStore Classic（已装好可跳过）

官方 Windows 安装说明：https://faq.altstore.io/altstore-classic/how-to-install-altstore-windows

1. 按官方说明准备兼容的 iTunes / iCloud 和 Windows AltServer。官方页面也列出 Microsoft Store 版 iCloud 的替代安装步骤。
2. 用 USB 连接 iPhone，解锁手机，选择信任这台电脑。
3. 在 Windows 打开 AltServer，按官方步骤安装 **AltStore Classic** 到你的 iPhone。
4. Apple 账号信息只在自己的官方 AltServer/AltStore 登录界面填写，不发到聊天、不提交到 GitHub。
5. iPhone 根据提示在 Settings → General → VPN & Device Management 信任自己的开发者身份。
6. iOS 16+ 根据官方步骤打开 Settings → Privacy & Security → Developer Mode，并按提示重启确认。

这里使用支持导入自制 IPA 的 AltStore Classic，不是 AltStore PAL 的商店发布流程。

## 4. 安装 PriceMY

1. Windows 保持 AltServer 运行。
2. iPhone 与电脑连接 USB，或使用允许设备互相通信的同一 Wi-Fi。
3. 将 `PriceMY-unsigned.ipa` 存到 iPhone 的 Files / 文件 App（例如通过你自己的 iCloud Drive）。如果文件带云朵标志，先下载到手机。
4. iPhone 打开 AltStore → **My Apps** → **+** → 选择 `PriceMY-unsigned.ipa`。
5. 等待 AltStore 签名和安装完成；按它的提示操作。
6. 回主屏幕打开 PriceMY。它仍是模拟价格原型，登录/扫码为演示，不会连接真实 retailer 或相机。

## 5. 后续刷新

普通免费账号下，侧载 App 通常 7 天后签名到期。到期前打开 AltStore → My Apps → Refresh All，并保持 AltServer 可连接。
免费账号通常最多同时启用 3 个侧载 App，AltStore 本身也占一个位置。不要删掉其他 App 的数据来盲目排错；如果出现槽位/App ID 限制，先查看具体提示。

## 官方参考

- 手动触发 workflow：https://docs.github.com/en/actions/how-tos/manage-workflow-runs/manually-run-a-workflow
- 下载产物：https://docs.github.com/en/actions/how-tos/manage-workflow-runs/download-workflow-artifacts
- AltServer 连接条件：https://faq.altstore.io/altstore-classic/altserver
- AltStore Windows：https://faq.altstore.io/altstore-classic/how-to-install-altstore-windows
- AltStore 刷新：https://faq.altstore.io/altstore-classic/your-altstore

## PriceCatcher 0.2 update

This source version uses real PriceCatcher observations, initially Petaling / Selangor. It does not require a deployed backend to view its bundled snapshot. To update over the internet, deploy the API and importer described in README, then add GitHub repository variable `API_BASE_URL` containing your HTTPS API origin before running the iOS workflow. Refresh is available in Profile. Without that setting, prices are a dated offline snapshot; rebuilding with a newly imported asset also updates them.

No IPA has been compiled or tested on an iPhone in this execution environment. A successful GitHub Actions macOS build is still required. Barcode scanning cannot find PriceCatcher items because the source supplies no GTIN mapping.
