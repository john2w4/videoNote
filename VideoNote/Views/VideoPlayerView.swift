import SwiftUI
import AVKit

/// 视频播放器视图
struct VideoPlayerView: View {
    @ObservedObject var viewModel: SearchViewModel
    
    var body: some View {
        ZStack {
            if let player = viewModel.player {
                VideoPlayer(player: player)
                    .onAppear {
                        // 播放器出现时自动播放
                        player.play()
                    }
            } else {
                // 占位视图
                placeholderView
            }
            
            // 字幕显示层
            SubtitleView(viewModel: viewModel)
        }
        .background(Color.black)
        .cornerRadius(8)
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
