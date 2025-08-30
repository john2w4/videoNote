import SwiftUI
import AVKit

/// 视频播放器视图 - 修复Archive构建崩溃问题
struct VideoPlayerView: View {
    @ObservedObject var viewModel: SearchViewModel
    @FocusState private var isFocused: Bool
    @State private var isPlayerReady = false
    
    var body: some View {
        ZStack {
            if let player = viewModel.player, isPlayerReady {
                // 使用SafeVideoPlayerView来避免Archive优化问题
                SafeVideoPlayerView(player: player)
                    .id(viewModel.currentVideoFile?.url.path ?? "")
            } else {
                // 占位视图
                placeholderView
            }
            
            // 错误提示
            if let errorMessage = viewModel.errorMessage {
                errorOverlay(errorMessage: errorMessage)
            }
            
            // 字幕显示层
            SubtitleView(viewModel: viewModel)
        }
        .background(Color.black)
        .cornerRadius(8)
        .onAppear {
            isFocused = true
            // 延迟初始化播放器以确保完全加载
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPlayerReady = true
            }
        }
        .onChange(of: viewModel.player) { _ in
            // 当播放器改变时重新初始化
            isPlayerReady = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPlayerReady = true
            }
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
    private func errorOverlay(errorMessage: String) -> some View {
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
            
            Button("关闭") {
                viewModel.errorMessage = nil
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding()
        .frame(maxWidth: 300)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
                .shadow(radius: 8)
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.3))
        .onTapGesture {
            viewModel.errorMessage = nil
        }
    }
}

#Preview {
    VideoPlayerView(viewModel: SearchViewModel())
        .frame(width: 400, height: 300)
}
