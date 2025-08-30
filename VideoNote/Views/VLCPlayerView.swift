import SwiftUI
// import VLCKit  // TODO: 添加 VLCKit 依赖后取消注释

/// VLC 播放器视图 - 支持更多视频格式包括 MKV
/// 注意: 需要先添加 VLCKit 依赖才能使用
struct VLCPlayerView: NSViewRepresentable {
    @ObservedObject var viewModel: SearchViewModel
    let videoURL: URL
    
    func makeNSView(context: Context) -> NSView {
        // TODO: VLCKit 依赖添加后，取消注释以下代码并删除此占位实现
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.black.cgColor
        
        // 添加说明文字
        let textField = NSTextField()
        textField.stringValue = "VLCKit 未安装\n请按照 setup_vlc_dependency.md 添加依赖"
        textField.isEditable = false
        textField.isBordered = false
        textField.backgroundColor = .clear
        textField.textColor = .white
        textField.alignment = .center
        textField.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(textField)
        NSLayoutConstraint.activate([
            textField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            textField.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        return view
        
        /* VLCKit 依赖添加后，使用以下代码替换上述占位实现:
        
        let vlcView = VLCVideoView()
        
        // 创建 VLC 媒体播放器
        let player = VLCMediaPlayer()
        player.delegate = context.coordinator
        vlcView.mediaPlayer = player
        
        // 设置媒体
        let media = VLCMedia(url: videoURL)
        player.media = media
        
        context.coordinator.vlcPlayer = player
        context.coordinator.vlcView = vlcView
        
        return vlcView
        */
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        // TODO: VLCKit 依赖添加后取消注释
        /*
        // 如果 URL 改变，更新媒体
        if let currentMedia = context.coordinator.vlcPlayer?.media,
           currentMedia.url != videoURL {
            let media = VLCMedia(url: videoURL)
            context.coordinator.vlcPlayer?.media = media
        }
        */
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }
    
    class Coordinator: NSObject {
        let viewModel: SearchViewModel
        // TODO: VLCKit 依赖添加后取消注释以下属性
        // var vlcPlayer: VLCMediaPlayer?
        // var vlcView: VLCVideoView?
        
        init(viewModel: SearchViewModel) {
            self.viewModel = viewModel
        }
        
        // TODO: VLCKit 依赖添加后取消注释以下代码
        /* VLCMediaPlayerDelegate 方法:
        
        // MARK: - VLCMediaPlayerDelegate
        
        func mediaPlayerStateChanged(_ aNotification: Notification) {
            guard let player = aNotification.object as? VLCMediaPlayer else { return }
            
            DispatchQueue.main.async {
                switch player.state {
                case .error:
                    self.viewModel.errorMessage = "VLC 播放失败: \(player.media?.url?.lastPathComponent ?? "未知文件")"
                case .ended:
                    print("📺 视频播放结束")
                case .playing:
                    print("▶️ VLC 开始播放")
                    self.viewModel.errorMessage = nil
                case .paused:
                    print("⏸️ VLC 暂停播放")
                case .stopped:
                    print("⏹️ VLC 停止播放")
                case .opening:
                    print("🔄 VLC 正在打开媒体")
                case .buffering:
                    print("⏳ VLC 正在缓冲")
                default:
                    break
                }
            }
        }
        
        func mediaPlayerTimeChanged(_ aNotification: Notification) {
            // 可以在这里更新播放进度
        }
        
        func mediaPlayerTitleChanged(_ aNotification: Notification) {
            print("📺 VLC 标题改变")
        }
        */
    }
}

/// VLC 播放器控制器
/// 注意: 需要先添加 VLCKit 依赖才能使用
class VLCPlayerController: ObservableObject {
    // TODO: VLCKit 依赖添加后取消注释
    // private var mediaPlayer: VLCMediaPlayer?
    // private var videoView: VLCVideoView?
    
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var volume: Float = 0.5
    
    init() {
        // setupPlayer() // TODO: VLCKit 依赖添加后取消注释
    }
    
    // TODO: VLCKit 依赖添加后取消注释以下所有方法
    /*
    private func setupPlayer() {
        mediaPlayer = VLCMediaPlayer()
        mediaPlayer?.delegate = self
        
        // 设置音量
        mediaPlayer?.audio?.volume = Int32(volume * 100)
    }
    
    func setVideoView(_ view: VLCVideoView) {
        videoView = view
        mediaPlayer?.drawable = view
    }
    
    func loadMedia(url: URL) {
        let media = VLCMedia(url: url)
        mediaPlayer?.media = media
        print("🎬 VLC 加载媒体: \(url.lastPathComponent)")
    }
    
    func play() {
        mediaPlayer?.play()
        isPlaying = true
        print("▶️ VLC 开始播放")
    }
    
    func pause() {
        mediaPlayer?.pause()
        isPlaying = false
        print("⏸️ VLC 暂停播放")
    }
    
    func stop() {
        mediaPlayer?.stop()
        isPlaying = false
        print("⏹️ VLC 停止播放")
    }
    
    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    func seek(to time: TimeInterval) {
        let vlcTime = VLCTime(number: NSNumber(value: time * 1000)) // VLC uses milliseconds
        mediaPlayer?.time = vlcTime
        print("🎯 VLC 跳转到: \(time)秒")
    }
    
    func fastForward(by seconds: TimeInterval) {
        let currentTime = Double(mediaPlayer?.time?.intValue ?? 0) / 1000.0
        seek(to: currentTime + seconds)
    }
    
    func rewind(by seconds: TimeInterval) {
        let currentTime = Double(mediaPlayer?.time?.intValue ?? 0) / 1000.0
        seek(to: max(0, currentTime - seconds))
    }
    
    func setVolume(_ volume: Float) {
        self.volume = volume
        mediaPlayer?.audio?.volume = Int32(volume * 100)
    }
    
    deinit {
        stop()
        mediaPlayer = nil
    }
    */
    
    // 临时占位方法，VLCKit 添加后删除
    func play() {
        isPlaying = true
        print("⚠️ VLC 播放器未安装，请添加 VLCKit 依赖")
    }
    
    func pause() {
        isPlaying = false
        print("⚠️ VLC 播放器未安装，请添加 VLCKit 依赖")
    }
    
    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    func fastForward(by seconds: TimeInterval) {
        print("⚠️ VLC 播放器未安装，快进功能不可用")
    }
    
    func rewind(by seconds: TimeInterval) {
        print("⚠️ VLC 播放器未安装，快退功能不可用")
    }
}

// TODO: VLCKit 依赖添加后取消注释以下扩展
/*
// MARK: - VLCMediaPlayerDelegate
extension VLCPlayerController: VLCMediaPlayerDelegate {
    func mediaPlayerStateChanged(_ aNotification: Notification) {
        guard let player = aNotification.object as? VLCMediaPlayer else { return }
        
        DispatchQueue.main.async {
            switch player.state {
            case .playing:
                self.isPlaying = true
            case .paused, .stopped, .ended:
                self.isPlaying = false
            case .error:
                self.isPlaying = false
                print("❌ VLC 播放错误")
            default:
                break
            }
        }
    }
    
    func mediaPlayerTimeChanged(_ aNotification: Notification) {
        guard let player = aNotification.object as? VLCMediaPlayer else { return }
        
        DispatchQueue.main.async {
            if let time = player.time {
                self.currentTime = Double(time.intValue) / 1000.0
            }
            
            if let media = player.media, let duration = media.length {
                self.duration = Double(duration.intValue) / 1000.0
            }
        }
    }
}
*/
