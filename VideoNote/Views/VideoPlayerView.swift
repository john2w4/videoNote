import SwiftUI
import AVKit

/// 视频播放器视图
struct VideoPlayerView: View {
    @ObservedObject var viewModel: SearchViewModel
    @FocusState private var isFocused: Bool
    @State private var useVLCPlayer = false
    
    var body: some View {
        ZStack {
            if useVLCPlayer, let currentVideoFile = viewModel.currentVideoFile {
                // 使用 VLC 播放器
                VLCPlayerView(viewModel: viewModel, videoURL: currentVideoFile.url)
                    .onAppear {
                        print("🎬 切换到 VLC 播放器")
                    }
                    .focused($isFocused)
                    .onTapGesture {
                        isFocused = true
                    }
            } else if let player = viewModel.player {
                // 使用系统默认播放器
                VideoPlayer(player: player)
                    .onAppear {
                        // 播放器出现时自动播放
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            player.play()
                        }
                    }
                    .focused($isFocused)
                    .onTapGesture {
                        isFocused = true
                    }
            } else {
                // 占位视图
                placeholderView
            }
            
            // 错误提示和外部播放器选项
            if let errorMessage = viewModel.errorMessage, 
               let currentVideo = viewModel.currentVideoFile {
                errorOverlay(errorMessage: errorMessage, videoFile: currentVideo)
            }
            
            // 字幕显示层
            SubtitleView(viewModel: viewModel)
        }
        .background(Color.black)
        .cornerRadius(8)
        .onAppear {
            isFocused = true
        }
    }
    
    private var placeholderView: some View {
        VStack(spacing: 20) {
            Image(systemName: "play.rectangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("选择搜索结果播放视频")
                .font(.headline)
                .foregroundColor(.gray)
            
            Text("视频将在此处显示")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                )
        )
    }
    
    @ViewBuilder
    private func errorOverlay(errorMessage: String, videoFile: VideoFile) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(.orange)
            
            Text("播放失败")
                .font(.headline)
                .foregroundColor(.primary)
            
            ScrollView {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .frame(maxHeight: 100)
            
            if videoFile.url.pathExtension.lowercased() == "mkv" {
                VStack(spacing: 8) {
                    // VLC 集成播放器选项
                    Button("使用内置 VLC 播放器") {
                        viewModel.errorMessage = nil
                        useVLCPlayer = true
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    
                    let availablePlayers = viewModel.getAvailableExternalPlayers()
                    
                    if !availablePlayers.isEmpty {
                        Text("或使用外部播放器:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            if availablePlayers.contains("VLC") {
                                Button("用 VLC 打开") {
                                    viewModel.openWithExternalPlayer(videoFile, playerBundleId: "org.videolan.vlc")
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                            
                            if availablePlayers.contains("IINA") {
                                Button("用 IINA 打开") {
                                    viewModel.openWithExternalPlayer(videoFile, playerBundleId: "com.colliderli.iina")
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }
                    }
                    
                    // 如果没有可用的外部播放器，提供下载链接
                    if availablePlayers.isEmpty {
                        Text("推荐下载:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Button("下载 VLC") {
                                viewModel.openPlayerDownloadPage(for: "VLC Media Player")
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            
                            Button("下载 IINA") {
                                viewModel.openPlayerDownloadPage(for: "IINA")
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                    
                    Button("用默认播放器打开") {
                        viewModel.openWithExternalPlayer(videoFile)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    
                    Button("关闭错误提示") {
                        viewModel.errorMessage = nil
                    }
                    .buttonStyle(.borderless)
                    .controlSize(.small)
                    .foregroundColor(.secondary)
                }
            } else {
                Button("关闭") {
                    viewModel.errorMessage = nil
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding()
        .frame(maxWidth: 300)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
                .shadow(radius: 8)
        )
    }
}

#Preview {
    // For preview, we need a mock view model
    struct PreviewWrapper: View {
        @StateObject var viewModel = SearchViewModel()
        
        var body: some View {
            VideoPlayerView(viewModel: viewModel)
                .frame(width: 400, height: 300)
        }
    }
    return PreviewWrapper()
}
