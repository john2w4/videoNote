#!/bin/bash

# VLCKit 安装脚本
# 用于在 VideoNote 项目中安装 VLCKit 依赖

echo "🎬 VideoNote VLCKit 集成安装脚本"
echo "======================================="

# 检查是否已安装 CocoaPods
if ! command -v pod &> /dev/null; then
    echo "❌ CocoaPods 未安装"
    echo "正在安装 CocoaPods..."
    sudo gem install cocoapods
fi

echo "✅ CocoaPods 已准备就绪"

# 检查 Podfile 是否存在
if [ ! -f "Podfile" ]; then
    echo "❌ Podfile 不存在"
    echo "请确保当前目录包含 Podfile"
    exit 1
fi

echo "📋 找到 Podfile"

# 初始化 CocoaPods（如果需要）
if [ ! -d "Pods" ]; then
    echo "🔧 初始化 CocoaPods 设置..."
    pod setup
fi

# 安装依赖
echo "📦 安装 VLCKit 依赖..."
pod install --repo-update

# 检查安装结果
if [ $? -eq 0 ]; then
    echo ""
    echo "✅ VLCKit 安装成功！"
    echo ""
    echo "🔧 接下来的步骤:"
    echo "1. 使用 VideoNote.xcworkspace 而不是 .xcodeproj 文件打开项目"
    echo "2. 在 Xcode 中构建项目以验证 VLCKit 集成"
    echo "3. 测试 MKV 文件播放功能"
    echo ""
    echo "⚠️  重要提醒:"
    echo "- 请确保你的 macOS 版本支持 VLCKit (macOS 13.0+)"
    echo "- 如果遇到签名问题，请在项目设置中配置开发团队"
    echo ""
else
    echo ""
    echo "❌ VLCKit 安装失败"
    echo ""
    echo "🔍 可能的解决方案:"
    echo "1. 检查网络连接"
    echo "2. 更新 CocoaPods: sudo gem install cocoapods"
    echo "3. 清理缓存: pod cache clean --all"
    echo "4. 重新运行: ./install_vlckit.sh"
    echo ""
fi

# 显示项目结构提醒
echo "📁 项目文件结构:"
echo "VideoNote.xcworkspace  ← 使用这个文件打开项目"
echo "VideoNote.xcodeproj    ← 不要使用这个"
echo "Podfile                ← CocoaPods 配置"
echo "Pods/                  ← 依赖库目录"
