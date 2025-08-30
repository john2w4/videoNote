# VLCKit 集成指南

本指南将帮助您在 VideoNote 应用中集成 VLCKit，以支持更多视频格式（特别是 MKV 文件）。

## 📋 前提条件

- macOS 13.0 或更高版本
- Xcode 15.0 或更高版本
- CocoaPods (将自动安装)

## 🚀 快速安装

### 方法一：自动安装脚本

1. 打开终端并导航到项目目录：
```bash
cd /path/to/VideoNote
```

2. 运行安装脚本：
```bash
./install_vlckit.sh
```

### 方法二：手动安装

1. 安装 CocoaPods（如果未安装）：
```bash
sudo gem install cocoapods
```

2. 安装项目依赖：
```bash
pod install
```

3. 使用生成的 workspace 文件打开项目：
```bash
open VideoNote.xcworkspace
```

## 🔧 配置说明

### Podfile 配置

项目已包含以下 Podfile 配置：

```ruby
platform :osx, '13.0'

target 'VideoNote' do
  use_frameworks!
  pod 'VLCKit', :git => 'https://github.com/videolan/vlckit.git', :branch => 'master'
end
```

### 项目设置

1. **使用 Workspace**: 安装后，始终使用 `VideoNote.xcworkspace` 而不是 `.xcodeproj` 文件
2. **构建设置**: VLCKit 需要禁用 Bitcode
3. **签名**: 确保在项目设置中配置正确的开发团队

## 🎬 VLC 播放器功能

### 集成的组件

1. **VLCPlayerView**: SwiftUI 视图组件，封装 VLC 播放器
2. **VLCPlayerController**: 播放器控制类，提供播放控制功能
3. **混合播放器策略**: 优先使用 AVPlayer，失败时自动切换到 VLC

### 支持的格式

VLCKit 支持以下额外格式：
- **MKV**: Matroska 视频容器
- **AVI**: Audio Video Interleave
- **FLV**: Flash Video
- **WebM**: WebM 视频格式
- **OGV**: Ogg 视频格式
- 以及更多编解码器组合

### 使用方式

#### 在代码中使用

```swift
// 在 VideoPlayerView 中
if useVLCPlayer, let currentVideoFile = viewModel.currentVideoFile {
    VLCPlayerView(viewModel: viewModel, videoURL: currentVideoFile.url)
} else if let player = viewModel.player {
    VideoPlayer(player: player)
}
```

#### 错误处理时自动切换

当 AVPlayer 无法播放 MKV 文件时，用户会看到错误提示：
- **使用内置 VLC 播放器**: 在应用内使用 VLC 引擎
- **使用外部播放器**: 调用系统安装的 VLC 或 IINA

## 🔍 故障排除

### 常见问题

1. **构建失败 - 找不到 VLCKit**
   ```
   解决方案：确保使用 .xcworkspace 文件而不是 .xcodeproj
   ```

2. **运行时崩溃 - VLC 库加载失败**
   ```
   解决方案：检查 macOS 版本兼容性，确保是 macOS 13.0+
   ```

3. **签名错误**
   ```
   解决方案：在项目设置 > Signing & Capabilities 中配置开发团队
   ```

### 调试命令

```bash
# 清理 Pod 缓存
pod cache clean --all

# 重新安装依赖
pod deintegrate
pod install

# 检查 VLCKit 版本
pod outdated
```

## 📱 测试验证

### 测试 MKV 播放

1. 准备一个 MKV 测试文件
2. 在 VideoNote 中尝试播放
3. 验证错误处理界面显示
4. 点击"使用内置 VLC 播放器"
5. 确认视频正常播放

### 验证键盘快捷键

- **左箭头键**: 后退 5 秒
- **右箭头键**: 前进 5 秒
- **空格键**: 播放/暂停

这些快捷键在 VLC 播放器中也应该正常工作。

## 🔄 更新 VLCKit

要更新到最新版本的 VLCKit：

```bash
pod update VLCKit
```

## 📚 相关资源

- [VLCKit GitHub 仓库](https://github.com/videolan/vlckit)
- [VLC 官方文档](https://wiki.videolan.org/LibVLC/)
- [CocoaPods 官方网站](https://cocoapods.org/)

## ⚠️ 注意事项

1. **性能影响**: VLCKit 是一个较大的库，会增加应用大小
2. **兼容性**: 某些旧版本的 macOS 可能不支持最新的 VLCKit
3. **许可证**: VLCKit 使用 LGPL 许可证，请确保了解许可证要求

## 🆘 获取帮助

如果遇到问题：

1. 检查控制台日志中的错误信息
2. 确认所有依赖已正确安装
3. 验证项目配置和构建设置
4. 参考故障排除部分的解决方案
