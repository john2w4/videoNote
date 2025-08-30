import SwiftUI
import AVKit

/// 字幕显示视图
///
/// 这个视图负责在视频播放器上层叠加显示当前时间的字幕。
struct SubtitleView: View {
    // 从环境中获取SearchViewModel的实例
    @ObservedObject var viewModel: SearchViewModel
    
    var body: some View {
        VStack {
            Spacer() // 将字幕推到底部
            
            // 检查是否有当前字幕文本，并且不为空
            if let subtitleText = viewModel.currentSubtitleText, !subtitleText.isEmpty {
                Text(subtitleText)
                    .font(.title2) // 增大字体大小 (从 title3 到 title2)
                    .fontWeight(.semibold) // 增加字体粗细 (从 medium 到 semibold)
                    .foregroundColor(.white) // 字体颜色
                    .padding(.horizontal, 16) // 增加水平内边距
                    .padding(.vertical, 12) // 增加垂直内边距
                    .background(
                        // 使用半透明的黑色背景以增强可读性
                        Color.black.opacity(0.75) // 稍微增加背景透明度
                    )
                    .cornerRadius(12) // 增大圆角
                    .padding(.bottom, 40) // 增加距离底部的边距
                    .transition(.opacity.animation(.easeInOut(duration: 0.2))) // 平滑的淡入淡出效果
                    .shadow(radius: 6) // 增加阴影
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) // 占据整个父视图空间
        .allowsHitTesting(false) // 允许鼠标事件穿透此视图，以免干扰播放器控制
    }
}
