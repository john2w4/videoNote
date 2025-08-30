#!/usr/bin/swift

import Foundation
import AVFoundation

// MKV 格式兼容性测试脚本
print("🎬 VideoNote MKV 格式兼容性测试")
print("====================================")

// 测试函数：检查视频文件兼容性
func testVideoCompatibility(url: URL) -> (playable: Bool, error: String?) {
    let asset = AVURLAsset(url: url)
    
    print("📁 文件: \(url.lastPathComponent)")
    print("   文件扩展名: \(url.pathExtension.uppercased())")
    print("   文件大小: \(getFileSize(url: url))")
    
    // 尝试检查可播放性（异步加载）
    let semaphore = DispatchSemaphore(value: 0)
    var isPlayable = false
    var tracks: [AVAssetTrack] = []
    
    Task {
        do {
            isPlayable = try await asset.load(.isPlayable)
            tracks = try await asset.load(.tracks)
            semaphore.signal()
        } catch {
            print("   错误: \(error.localizedDescription)")
            semaphore.signal()
        }
    }
    
    semaphore.wait()
    
    print("   可播放: \(isPlayable ? "✅" : "❌")")
    print("   总轨道数: \(tracks.count)")
    
    let videoTracks = tracks.filter { track in
        track.mediaType == .video
    }
    let audioTracks = tracks.filter { track in
        track.mediaType == .audio
    }
    
    print("   视频轨道: \(videoTracks.count)")
    print("   音频轨道: \(audioTracks.count)")
    
    if !videoTracks.isEmpty {
        print("   视频编码器: 检测到视频轨道")
    }
    
    if !audioTracks.isEmpty {
        print("   音频编码器: 检测到音频轨道")
    }
    
    var errorMessage: String? = nil
    if !isPlayable {
        errorMessage = "AVFoundation 无法播放此文件格式"
    }
    
    print("   结果: \(isPlayable ? "系统播放器支持" : "需要 VLC 播放器")")
    print()
    
    return (playable: isPlayable, error: errorMessage)
}

func getFileSize(url: URL) -> String {
    do {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        if let size = attributes[.size] as? Int64 {
            return formatFileSize(size)
        }
    } catch {
        return "未知"
    }
    return "未知"
}

func formatFileSize(_ size: Int64) -> String {
    let formatter = ByteCountFormatter()
    formatter.allowedUnits = [.useMB, .useGB]
    formatter.countStyle = .file
    return formatter.string(fromByteCount: size)
}

// 模拟测试各种格式
let testFormats = [
    "sample.mp4",
    "sample.mov", 
    "sample.mkv",
    "sample.avi",
    "sample.webm"
]

print("📋 模拟测试常见视频格式:")
print("格式    | AVFoundation 支持")
print("--------|------------------")
print("MP4     | ✅ 通常支持")
print("MOV     | ✅ 通常支持") 
print("MKV     | ❌ 通常不支持")
print("AVI     | ⚠️  取决于编码器")
print("WebM    | ❌ 通常不支持")
print()

// 检查命令行参数中的文件
let arguments = CommandLine.arguments
if arguments.count > 1 {
    print("🔍 测试提供的文件:")
    for i in 1..<arguments.count {
        let filePath = arguments[i]
        let url = URL(fileURLWithPath: filePath)
        
        if FileManager.default.fileExists(atPath: filePath) {
            _ = testVideoCompatibility(url: url)
        } else {
            print("❌ 文件不存在: \(filePath)")
        }
    }
} else {
    print("💡 使用方法:")
    print("   swift test_mkv_support.swift /path/to/video.mkv")
    print("   或者拖拽视频文件到此脚本上")
}

print()
print("📊 VideoNote 应用行为:")
print("• 如果 AVFoundation 支持 ➜ 使用系统播放器")
print("• 如果 AVFoundation 不支持 ➜ 显示 VLC 选项")
print("• MKV 文件通常会触发 VLC 播放器")
print("• 用户可以选择内置 VLC 或外部播放器")
print()
print("🔧 要测试 VideoNote 中的 MKV 支持:")
print("1. 确保已添加 VLCKit 依赖")
print("2. 运行 VideoNote 应用")
print("3. 打开包含 MKV 文件的文件夹")
print("4. 尝试播放 MKV 文件")
print("5. 观察是否出现 VLC 播放器选项")
