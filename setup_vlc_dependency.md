# VLCKit 依赖集成指南

## 1. 在 Xcode 中添加 VLCKit 依赖

### 方法 1: 通过 Swift Package Manager（推荐）

1. 打开 `VideoNote.xcodeproj`
2. 选择项目 "VideoNote" 在项目导航器中
3. 选择 "VideoNote" target
4. 点击 "Package Dependencies" 标签
5. 点击 "+" 按钮添加新的包依赖
6. 输入 VLCKit 的 GitHub URL: `https://github.com/videolan/vlckit`
7. 选择版本或分支（推荐使用最新稳定版本）
8. 点击 "Add Package"
9. 在弹出的对话框中选择 "VLCKit" 并点击 "Add Package"

### 方法 2: 手动添加 VLCKit Framework

如果 Swift Package Manager 方式不可用，可以：

1. 从 [VLC 官网](https://get.videolan.org/vlckit/) 下载 VLCKit.framework
2. 将下载的框架拖拽到 Xcode 项目中的 "Frameworks" 文件夹
3. 确保在 target 设置中的 "Frameworks, Libraries, and Embedded Content" 中包含 VLCKit.framework
4. 将 "Embed" 设置为 "Embed & Sign"

## 2. 配置项目设置

### 添加必要的权限

在 `VideoNote.entitlements` 文件中添加：

```xml
<key>com.apple.security.network.client</key>
<true/>
<key>com.apple.security.files.user-selected.read-only</key>
<true/>
```

### 更新 Info.plist

如果需要播放网络视频，在 `Info.plist` 中添加：

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

## 3. 验证集成

运行项目，VLC 播放器应该能够：
- 自动处理 MKV 格式文件
- 提供更好的格式兼容性
- 在系统播放器失败时作为备选方案

## 4. 故障排除

### 编译错误
- 确保 VLCKit 版本与 macOS 目标版本兼容
- 检查架构设置 (arm64/x86_64)

### 运行时错误
- 确保 VLCKit.framework 正确嵌入到应用包中
- 检查代码签名设置

### 性能优化
- VLC 播放器仅在系统播放器失败时使用
- 可以根据文件格式预先选择播放器类型

## 5. 当前代码状态

✅ VLCPlayerView.swift - VLC 播放器组件已实现
✅ VideoPlayerView.swift - 支持动态切换到 VLC 播放器
✅ SearchViewModel.swift - 包含 MKV 兼容性检查
⏳ VLCKit 依赖 - 需要在 Xcode 中手动添加

添加依赖后，应用将自动支持更多视频格式！
