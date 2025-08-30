import SwiftUI

/// 搜索结果行视图
struct SearchResultRow: View {
    let result: SearchResult
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // 时间标签
            timeLabel
            
            // 内容区域
            VStack(alignment: .leading, spacing: 4) {
                // 字幕内容
                subtitleContent
                
                // 文件信息
                fileInfo
            }
            
            Spacer()
            
            // 播放图标
            if isSelected || isHovered {
                playIcon
            }
        }
        .padding(12)
        .background(backgroundView)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .onTapGesture {
            onTap()
        }
        .contextMenu {
            contextMenuItems
        }
    }
    
    // MARK: - Components
    private var timeLabel: some View {
        Text(result.formattedTime)
            .font(.system(.caption, design: .monospaced))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.accentColor.opacity(0.1))
            .foregroundColor(.accentColor)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
            )
    }
    
    private var subtitleContent: some View {
        Text(attributedContent)
            .font(.body)
            .lineLimit(3)
            .multilineTextAlignment(.leading)
    }
    
    private var fileInfo: some View {
        HStack(spacing: 6) {
            Image(systemName: "doc.text")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text(result.subtitleEntry.sourceFileName)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            if result.subtitleEntry.associatedVideoPath != nil {
                Image(systemName: "video.fill")
                    .font(.caption2)
                    .foregroundColor(.green)
            } else {
                Image(systemName: "video.slash")
                    .font(.caption2)
                    .foregroundColor(.orange)
            }
        }
    }
    
    private var playIcon: some View {
        Image(systemName: isSelected ? "play.circle.fill" : "play.circle")
            .font(.title2)
            .foregroundColor(isSelected ? .accentColor : .secondary)
            .transition(.scale.combined(with: .opacity))
    }
    
    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
    }
    
    private var contextMenuItems: some View {
        Group {
            Button("播放视频") {
                onTap()
            }
            
            Divider()
            
            Button("复制字幕内容") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(result.subtitleEntry.content, forType: .string)
            }
            
            Button("复制时间戳") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(result.formattedTime, forType: .string)
            }
            
            if let videoPath = result.subtitleEntry.associatedVideoPath {
                Divider()
                
                Button("在Finder中显示视频") {
                    NSWorkspace.shared.selectFile(videoPath.path, inFileViewerRootedAtPath: "")
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    private var attributedContent: AttributedString {
        var attributedString = AttributedString(result.subtitleEntry.content)
        
        // 高亮搜索关键词
        if !result.searchKeyword.isEmpty {
            let range = attributedString.range(of: result.searchKeyword, options: [.caseInsensitive, .diacriticInsensitive])
            if let range = range {
                attributedString[range].backgroundColor = Color.yellow.opacity(0.3)
                attributedString[range].foregroundColor = Color.primary
            }
        }
        
        return attributedString
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return Color.accentColor.opacity(0.1)
        } else if isHovered {
            return Color.primary.opacity(0.05)
        } else {
            return Color.clear
        }
    }
    
    private var borderColor: Color {
        if isSelected {
            return Color.accentColor.opacity(0.3)
        } else {
            return Color.clear
        }
    }
    
    private var borderWidth: CGFloat {
        isSelected ? 1 : 0
    }
}

// MARK: - Preview
#Preview {
    let sampleEntry = SubtitleEntry(
        startTime: 90.5,
        endTime: 95.2,
        content: "这是一个示例字幕内容，用于演示搜索结果的显示效果。",
        sourceFilePath: URL(fileURLWithPath: "/path/to/sample.srt"),
        sequenceNumber: 1
    )
    
    let sampleResult = SearchResult(subtitleEntry: sampleEntry, searchKeyword: "示例")
    
    VStack(spacing: 8) {
        SearchResultRow(result: sampleResult, isSelected: false) {}
        SearchResultRow(result: sampleResult, isSelected: true) {}
    }
    .padding()
    .frame(width: 350)
}
