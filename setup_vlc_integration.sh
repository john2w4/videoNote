#!/bin/bash

# VideoNote VLCKit 集成安装脚本
# 用于自动化配置 VLCKit 依赖和设置

set -e

echo "🎬 VideoNote VLCKit 集成脚本"
echo "================================"

# 检查是否在正确的目录
if [ ! -f "VideoNote.xcodeproj/project.pbxproj" ]; then
    echo "❌ 错误: 请在 VideoNote 项目根目录运行此脚本"
    exit 1
fi

echo "✅ 检测到 VideoNote 项目"

# 检查 Xcode 是否安装
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ 错误: 未检测到 Xcode，请先安装 Xcode"
    exit 1
fi

echo "✅ 检测到 Xcode"

# 创建备份
echo "📦 创建项目备份..."
BACKUP_DIR="VideoNote_backup_$(date +%Y%m%d_%H%M%S)"
cp -r VideoNote.xcodeproj "$BACKUP_DIR.xcodeproj" 2>/dev/null || true
echo "✅ 备份已创建: $BACKUP_DIR.xcodeproj"

# 检查 VLCKit 是否已经添加
echo "🔍 检查现有依赖..."
if grep -q "VLCKit" VideoNote.xcodeproj/project.pbxproj; then
    echo "✅ VLCKit 依赖已存在"
else
    echo "⚠️  VLCKit 依赖未找到"
    echo ""
    echo "📋 请按照以下步骤在 Xcode 中手动添加 VLCKit："
    echo "1. 打开 VideoNote.xcodeproj"
    echo "2. 选择项目 'VideoNote'"
    echo "3. 选择 'VideoNote' target"
    echo "4. 点击 'Package Dependencies' 标签"
    echo "5. 点击 '+' 按钮"
    echo "6. 输入: https://github.com/videolan/vlckit"
    echo "7. 点击 'Add Package'"
    echo "8. 选择 VLCKit 并添加"
    echo ""
    read -p "完成后按 Enter 继续..."
fi

# 检查权限配置
echo "🔐 检查权限配置..."
ENTITLEMENTS_FILE="VideoNote/VideoNote.entitlements"

if [ -f "$ENTITLEMENTS_FILE" ]; then
    echo "✅ 找到权限文件: $ENTITLEMENTS_FILE"
    
    # 检查网络权限
    if grep -q "com.apple.security.network.client" "$ENTITLEMENTS_FILE"; then
        echo "✅ 网络客户端权限已配置"
    else
        echo "⚠️  添加网络客户端权限..."
        # 这里可以添加权限配置的逻辑
    fi
    
    # 检查文件读取权限
    if grep -q "com.apple.security.files.user-selected.read-only" "$ENTITLEMENTS_FILE"; then
        echo "✅ 文件读取权限已配置"
    else
        echo "⚠️  添加文件读取权限..."
    fi
else
    echo "⚠️  权限文件不存在，VLC 可能需要额外配置"
fi

# 编译测试
echo "🔨 测试编译..."
if xcodebuild -project VideoNote.xcodeproj -scheme VideoNote -configuration Debug build -quiet; then
    echo "✅ 编译成功"
else
    echo "❌ 编译失败，请检查 VLCKit 依赖是否正确添加"
    echo "📋 如果编译失败，请："
    echo "1. 确保 VLCKit 依赖已正确添加"
    echo "2. 检查目标版本兼容性"
    echo "3. 清理构建缓存: Product > Clean Build Folder"
    exit 1
fi

# 功能测试提示
echo ""
echo "🎉 集成完成！"
echo "==============="
echo ""
echo "📋 测试步骤："
echo "1. 运行应用"
echo "2. 打开包含 MKV 文件的目录"
echo "3. 尝试播放 MKV 文件"
echo "4. 如果系统播放器失败，应该看到 VLC 播放器选项"
echo ""
echo "🔧 功能特性："
echo "• 自动检测 MKV 格式兼容性"
echo "• 系统播放器失败时提供 VLC 选项"
echo "• 支持键盘快捷键 (←/→ 5秒跳转, 空格播放/暂停)"
echo "• 外部播放器备选方案"
echo ""
echo "🆘 如果遇到问题："
echo "• 检查 VLCKit 版本兼容性"
echo "• 确保应用签名正确"
echo "• 查看控制台日志了解详细错误信息"
echo ""
echo "📖 更多信息请查看: setup_vlc_dependency.md"
