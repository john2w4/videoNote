# VLCKit 依赖安装 - 完整指南

## 🎯 当前状态

✅ **应用已成功编译** - VLC 相关代码已暂时注释，不会阻止应用运行
⚠️ **VLCKit 依赖未安装** - 需要按以下步骤添加 VLCKit 支持

## 📋 安装步骤

### 方法1: 通过 Swift Package Manager（推荐）

1. **打开 Xcode 项目**
   ```bash
   open VideoNote.xcodeproj
   ```

2. **添加 Package 依赖**
   - 在项目导航器中选择 "VideoNote" 项目
   - 选择 "VideoNote" target
   - 点击 "Package Dependencies" 标签
   - 点击 "+" 按钮

3. **输入 VLCKit 仓库地址**
   ```
   https://github.com/videolan/vlckit-spm
   ```

4. **选择版本**
   - 选择 "Up to Next Major Version"
   - 版本选择: 4.0.0 或最新版本

5. **添加到项目**
   - 点击 "Add Package"
   - 在弹出的对话框中选择 "VLCKit"
   - 点击 "Add Package"

### 方法2: 手动下载 Framework（备选）

如果 SPM 方式不可用：

1. **下载 VLCKit**
   - 访问: https://get.videolan.org/vlckit/
   - 下载适合 macOS 的版本

2. **添加到项目**
   - 将 `VLCKit.framework` 拖拽到项目中
   - 确保在 "Frameworks, Libraries, and Embedded Content" 中设置为 "Embed & Sign"

## 🔧 激活 VLC 功能

VLCKit 依赖添加成功后，需要取消注释代码：

### 1. 修改 `VLCPlayerView.swift`

```swift
// 将第2行的注释删除
import VLCKit  // 取消注释

// 恢复 makeNSView 方法中的实际实现
// 删除占位代码，取消注释真正的 VLC 代码
```

### 2. 自动化恢复脚本

运行以下命令自动恢复所有 VLC 功能：

```bash
cd /path/to/VideoNote
./activate_vlc_features.sh
```

## 🧪 验证安装

### 编译测试
```bash
cd /Volumes/big/Users/wh/Documents/AI/VideoNote
xcodebuild -project VideoNote.xcodeproj -scheme VideoNote -configuration Debug build
```

### 功能测试
1. 运行应用
2. 打开包含 MKV 文件的文件夹
3. 尝试播放 MKV 文件
4. 如果系统播放器失败，应该看到 "使用内置 VLC 播放器" 选项

## ⚠️ 常见问题

### 编译错误
- **"no such module 'VLCKit'"** → VLCKit 依赖未正确添加
- **代码签名问题** → 确保 VLCKit 设置为 "Embed & Sign"
- **架构不兼容** → 确保 VLCKit 支持 arm64 (Apple Silicon)

### 运行时问题
- **VLC 无法播放** → 检查文件权限和网络访问权限
- **界面显示异常** → 确保 VLCVideoView 正确初始化

## 🎬 完成后的功能

✅ 支持播放 MKV、AVI、WebM 等格式
✅ 智能播放器切换（系统播放器失败时自动提供 VLC 选项）
✅ 键盘快捷键支持（←/→ 5秒跳转，空格播放/暂停）
✅ 统一的播放控制接口
✅ 外部播放器备选方案

## 🆘 需要帮助？

如果遇到问题：
1. 检查 Xcode 版本兼容性
2. 清理构建缓存: Product → Clean Build Folder
3. 重启 Xcode
4. 查看详细错误日志

---

**注意**: 当前应用已可正常编译和运行，只是 VLC 功能被暂时禁用。添加 VLCKit 依赖后，所有 MKV 支持功能将立即可用！
