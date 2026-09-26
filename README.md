# PriceMY · v0.1 Prototype

面向马来西亚的价格比较项目第一版。Flutter / Dart 前端 + FastAPI 模拟 API + Supabase SQL 架构。

**这是开发原型，不是已上线的比价服务。所有价格、分店距离、来源标签均为模拟；没有已接通的 retailer。**

## 先体验界面（无需安装）

解压后双击 `preview/index.html`，用 Chrome 或 Edge 打开。
这是独立的 HTML 交互设计预览，**不是 Flutter 编译产物**；使用同一套商品和价格 fixture。不需要服务器或联网。

体验路径：Splash → Onboarding → Login/Register（演示）→ Explore as guest → Home → Compare → Add to my list → My list → Scan → Profile。

- 搜索 `milk` 可看到不同口味、不同容量独立的商品。
- 扫码演示用 `DEMO-0001`；点击 Simulate a successful scan 也可以。
- Cheapest / Best value 切换，会员价可开关。
- 清单数量和价格提醒目标保存在本机；提醒尚不发送通知。
- Chrome 的本地文件存储策略可能不同；无法持久化时仍可体验当前会话。

## Flutter：Windows 11 + VS Code

1. 安装 Flutter SDK、VS Code Flutter 扩展；Android 真机/模拟器还需要 Android SDK。
2. 解压项目并用 VS Code 打开 `PriceMY` 文件夹。
3. 在终端运行 `flutter doctor`，处理目标平台所需项目。
4. 在 PowerShell 运行 `./scripts/bootstrap.ps1`。如本机策略不允许运行脚本，直接使用以下命令，无需修改全局执行策略：

```powershell
cd apps/mobile
flutter create --platforms=android,ios,web --org my.pricemy --project-name pricemy .
flutter pub get
# flutter create 若生成默认 counter 测试，仅删除 test/widget_test.dart；保留 catalogue_test.dart。
flutter analyze
flutter test
flutter run -d chrome
```

Android：`flutter devices` 查看设备，执行 `flutter run -d <device-id>`。
macOS：从根目录 `bash scripts/bootstrap.sh`，再进入 `apps/mobile` 运行 `flutter run`。
iOS 构建必须在配置 Xcode 的 macOS 环境完成；Windows 可开发共享 Dart 代码及 Android 版本。

本包保留 Flutter 应用源码和 pubspec；Android/iOS/Web 平台壳由本机 Flutter 工具生成，避免伪造或提供过期的 Gradle、Xcode 工程。首次 bootstrap 后请把生成的平台文件、pubspec.lock 提交到自己的 Git 仓库。

**当前环境没有 Flutter SDK；本次未执行 flutter analyze、flutter test 或 Android/iOS 构建。** Dart 语法解析不能替代 Flutter 编译。包中测试与 CI 可在安装 Flutter 的环境运行。

## FastAPI（独立模拟服务）

```powershell
cd backend
python -m venv .venv
.venv\Scripts\python -m pip install -r requirements-dev.txt
.venv\Scripts\python -m uvicorn app.main:app --reload
```

打开 `http://127.0.0.1:8000/docs` 查看 API。Linux/macOS 使用 `.venv/bin/python`。

Flutter 默认从本地 JSON 加载，不依赖 API；这一版尚未切换到 HTTP repository 或 Supabase Auth。FastAPI 提供同一数据的读取和比价接口，便于下一阶段联调。

## 已实现与边界

| 能力 | 当前状态 |
|---|---|
| Splash / 3 步 Onboarding / Login / Register | UI；表单校验；登录无网络账号 |
| Home / Search / Compare / Profile | Flutter 源码 + 可运行 HTML 预览 |
| Barcode | 输入示例码、成功/失败演示；无摄像头 |
| 同款比较 | 由 canonical product ID 隔离品牌、口味、容量 |
| Cheapest / Member / Unit price | 基于模拟 offer 计算 |
| Best Value | 可解释的价格 + 往返距离成本公式；不是 AI |
| Shopping List / Compare Basket / Smart Split | 数量增减、完整单店购物篮、逐商品低价拆单 |
| Price Alerts | 本地保存目标价；无后台监控和推送 |
| Price History | 诚实空状态；后端返回观察记录，无虚构趋势 |
| Retailers | 22 个计划品牌；5 个品牌有示例 offer；全部未连接 |
| Receipt / Monthly Savings | 预览/空状态；无 OCR、无伪造节省金额 |
| Supabase | migration + RLS + private receipt bucket，未部署 |
| AI / Nearby live map / Deals feed | 下一阶段；只有扩展接口/设计说明 |

## 目录

- `apps/mobile/lib/core`：主题、本地状态
- `apps/mobile/lib/data`：实体、repository 边界、mock repository、排名
- `apps/mobile/lib/features`：入口、首页、比较、扫描、购物清单
- `apps/mobile/lib/widgets`：公共卡片、标签、商品占位插画
- `backend/app`：FastAPI、领域计算、未来数据源和 AI 接口
- `supabase/migrations`：商品、retailer、分店、历史价格、用户、清单、收据、RLS
- `preview`：离线可点击设计预览
- `docs`：架构说明、验证记录、预览截图
- `scripts`：平台生成与本地验证

## 扩展 retailer

不要在 Flutter 页面里加商店条件分支。先添加 retailer/branch 数据，再通过服务端适配器导入价格、保留 provenance，并经过 canonical product 匹配。前端按数据渲染。沙巴/砂拉越通过 retailer.regions 与 branch.state 扩展；未虚构区域品牌的合作关系。

## 官方参考

- Flutter 项目：https://docs.flutter.dev/reference/create-new-app
- iOS 环境：https://docs.flutter.dev/platform-integration/ios/setup
- Supabase RLS：https://supabase.com/docs/guides/database/postgres/row-level-security
