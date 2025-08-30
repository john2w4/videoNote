#!/bin/bash

# VLC 功能激活脚本
# 在成功添加 VLCKit 依赖后运行此脚本

set -e

echo "🎬 VideoNote VLC 功能激活脚本"
echo "============================="

# 检查是否在正确的目录
if [ ! -f "VideoNote.xcodeproj/project.pbxproj" ]; then
    echo "❌ 错误: 请在 VideoNote 项目根目录运行此脚本"
    exit 1
fi

VLCPLAYER_FILE="VideoNote/Views/VLCPlayerView.swift"

if [ ! -f "$VLCPLAYER_FILE" ]; then
    echo "❌ 错误: 找不到 VLCPlayerView.swift 文件"
    exit 1
fi

echo "📁 找到 VLCPlayerView.swift 文件"

# 创建备份
BACKUP_FILE="${VLCPLAYER_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
cp "$VLCPLAYER_FILE" "$BACKUP_FILE"
echo "📦 已创建备份: $BACKUP_FILE"

# 激活 VLCKit import
echo "🔧 激活 VLCKit import..."
sed -i '' 's|// import VLCKit  // TODO: 添加 VLCKit 依赖后取消注释|import VLCKit|g' "$VLCPLAYER_FILE"

# 检查是否需要手动操作
if grep -q "TODO: VLCKit 依赖添加后" "$VLCPLAYER_FILE"; then
    echo ""
    echo "⚠️  注意: 检测到待激活的 VLC 代码"
    echo "   请手动取消注释 VLCPlayerView.swift 中的以下部分:"
    echo "   1. VLC 相关的实际实现代码"
    echo "   2. VLCMediaPlayerDelegate 方法"
    echo "   3. VLCPlayerController 的完整实现"
    echo ""
    echo "📝 或者在 Xcode 中搜索 'TODO: VLCKit' 来找到所有需要激活的代码"
fi

# 测试编译
echo ""
echo "🔨 测试编译..."
if xcodebuild -project VideoNote.xcodeproj -scheme VideoNote -configuration Debug build -quiet; then
    echo "✅ 编译成功！VLC 功能已激活"
    echo ""
    echo "🎉 VLC 集成完成！"
    echo "================="
    echo ""
    echo "📋 现在可以："
    echo "• 播放 MKV、AVI、WebM 等格式"
    echo "• 使用键盘快捷键控制播放"
    echo "• 在系统播放器失败时自动切换到 VLC"
    echo ""
    echo "🧪 测试建议："
    echo "1. 运行应用"
    echo "2. 打开包含 MKV 文件的文件夹"
    echo "3. 尝试播放 MKV 文件"
    echo "4. 验证 VLC 播放器选项是否出现"
else
    echo "❌ 编译失败"
    echo ""
    echo "可能的原因："
    echo "1. VLCKit 依赖未正确添加"
    echo "2. 需要手动激活更多 VLC 相关代码"
    echo "3. 版本兼容性问题"
    echo ""
    echo "🔄 恢复备份："
    echo "   cp '$BACKUP_FILE' '$VLCPLAYER_FILE'"
    exit 1
fi
