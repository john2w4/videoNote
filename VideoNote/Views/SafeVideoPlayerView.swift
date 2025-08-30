import SwiftUI
import AVKit

/// 安全的视频播放器视图 - 专门用于解决Archive构建优化问题
struct SafeVideoPlayerView: View {
    let player: AVPlayer
    
    var body: some View {
        SafeAVPlayerView(player: player)
    }
}

/// NSViewRepresentable包装器来安全地使用AVPlayerView
struct SafeAVPlayerView: NSViewRepresentable {
    let player: AVPlayer
    
    func makeNSView(context: Context) -> AVPlayerView {
        let playerView = AVPlayerView()
        playerView.player = player
        playerView.controlsStyle = .default
        playerView.videoGravity = .resizeAspect
        
        // 确保播放器在Archive模式下正确初始化
        DispatchQueue.main.async {
            playerView.player = player
        }
        
        return playerView
    }
    
    func updateNSView(_ nsView: AVPlayerView, context: Context) {
        if nsView.player !== player {
            nsView.player = player
        }
    }
    
    static func dismantleNSView(_ nsView: AVPlayerView, coordinator: ()) {
        nsView.player = nil
    }
}
