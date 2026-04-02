# TS3 for iOS

`TS3 for iOS` 是一个使用 Swift 编写的 TeamSpeak 3 客户端实现，包含完整的 TS3 协议栈、SwiftUI 图形界面，以及一个便于调试协议和语音链路的 CLI。

项目实现时参考了：

- `ts3j`（Java）
- `TS3AudioBot/TSLib`（C#）

## 当前能力

- 连接 TeamSpeak 3 服务器
- 支持带密码服务器连接
- 完成 TS3 握手、身份、加密命令传输
- 拉取并显示频道列表
- 显示各频道下的在线用户
- 标记当前所在频道，并支持切换频道
- 收听同频道用户语音
- Push To Talk 实时发送麦克风音频
- 调整接收音量，范围 `0%` 到 `400%`
- 内置调试日志页面
- 提供 `TS3CLI` 便于命令行连接和麦克风链路测试

## 支持平台

- iOS `14.0+`
- macOS `11.0+`（通过 Mac Catalyst）
- Swift `5.9+`
- 推荐使用 Xcode `16.4+`

仓库额外提供了一个共享 scheme：

- `TS3iOSApp-App`

它专门用于原生 App 构建，避免和 Swift Package 的同名 `TS3iOSApp` scheme 冲突。GitHub Actions 和命令行真机打包都基于这个 scheme。

## 项目结构

```text
.
├── Sources/
│   ├── TS3Kit/         # 核心协议与音频逻辑
│   ├── TS3iOSApp/      # SwiftUI 图形界面
│   └── TS3CLI/         # CLI 调试入口
├── vendor/             # 本地第三方依赖
├── ts3j/               # Java 参考实现
├── Package.swift
└── TS3iOSApp.xcodeproj
```

## 本地构建

### 1. Swift Package Manager

构建 CLI 和核心库：

```bash
swift build --product TS3CLI
```

使用 CLI 连接服务器：

```bash
swift run TS3CLI <host> <port> [nickname] [--server-password <password>] [--mic-seconds <seconds>]
```

示例：

```bash
swift run TS3CLI 120.24.89.226 9987 MyBot --server-password 114514
```

### 2. Xcode

```bash
open TS3iOSApp.xcodeproj
```

### 3. 命令行构建 App

构建 iOS Simulator 版本：

```bash
xcodebuild \
  -project TS3iOSApp.xcodeproj \
  -scheme TS3iOSApp-App \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

构建 Mac Catalyst 版本：

```bash
xcodebuild \
  -project TS3iOSApp.xcodeproj \
  -scheme TS3iOSApp-App \
  -configuration Debug \
  -destination 'generic/platform=macOS,variant=Mac Catalyst' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

构建未签名 `ipa`：

```bash
xcodebuild \
  -project TS3iOSApp.xcodeproj \
  -scheme TS3iOSApp-App \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -derivedDataPath build/DerivedData-iOSDevice \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  build

rm -rf build/ipa
mkdir -p build/ipa/Payload
cp -R build/DerivedData-iOSDevice/Build/Products/Release-iphoneos/TS3iOSApp.app build/ipa/Payload/
(
  cd build/ipa
  zip -qry ../TS3iOSApp-unsigned.ipa Payload
)
```

这个 `ipa` 是未签名版本，不能直接安装到 iPhone。用户需要自己重新签名后再安装。

## GitHub Actions

仓库内置了一个 `Build` 工作流，路径为：

```text
.github/workflows/build.yml
```

它会执行以下检查：

- `SwiftPM` 构建 `TS3CLI`
- 在 `macos-15` runner 上构建 iOS Simulator 版本
- 在 `macos-15` runner 上构建 iPhoneOS 未签名 `ipa`
- 在 `macos-15` 与 `macos-15-intel` runner 上分别构建 Mac Catalyst，覆盖 Apple Silicon 与 Intel
- 分别构建 `arm64` 和 `intel` 两个可拖拽安装的 macOS `dmg`

这个工作流刻意避免使用 `macos-latest`，减少 GitHub runner 切换镜像时带来的不确定性；同时使用 `generic/platform=...` destination，避免依赖某个具体模拟器名称或运行时版本。

## CI 产物

工作流会上传以下无签名产物：

- iOS Simulator `.app`
- iPhoneOS 未签名 `ipa`
- Mac Catalyst `.app`
- macOS `arm64` `.dmg`
- macOS `intel` `.dmg`

这些产物用于验证编译链路是否正常。

其中未签名 `ipa` 适合交给用户自己签名再安装，不依赖仓库内保存 Apple 证书或 provisioning profile。

## Release 上传

当你 push 任意 tag 时，工作流会自动：

- 构建未签名 `ipa`
- 构建 `arm64` 和 `intel` 两个可拖拽安装的 macOS `dmg`
- 创建或更新对应的 GitHub Release
- 把 `TS3iOSApp-unsigned.ipa`、`TS3iOSApp-macOS-arm64.dmg`、`TS3iOSApp-macOS-intel.dmg` 作为 Release assets 上传

每个 `dmg` 内都包含：

- `TS3iOSApp.app`
- `Applications` 软链接
- 一份简短安装说明

用户打开 `dmg` 后，可以把应用直接拖到 `Applications` 完成安装。

## 音频与权限说明

- iOS 真机上使用 Push To Talk 需要麦克风权限
- 模拟器上的麦克风行为可能不稳定，建议优先在真机测试
- macOS 通过 Mac Catalyst 运行时，同样需要授予麦克风权限

## 说明

- 本项目为非官方 TeamSpeak 客户端实现
- `ts3j/` 目录主要用于协议对照与调试，不参与 App 正式发布
