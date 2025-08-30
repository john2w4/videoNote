import SwiftUI
import Combine

/// Tab 控制视图
struct TabControlView: View {
    @Binding var selectedTab: ContentTab
    
    var body: some View {
        HStack(spacing: 2) { // 减少tab之间的间距，让点击区域更连续
            ForEach(ContentTab.allCases, id: \.self) { tab in
                Button(action: {
                    selectedTab = tab
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: tab.systemImage)
                            .font(.callout) // 调整图标大小 (从 body 到 callout)
                        
                        Text(tab.rawValue)
                            .font(.callout) // 调整字体大小 (从 body 到 callout)
                            .fontWeight(selectedTab == tab ? .semibold : .regular)
                    }
                    .padding(.horizontal, 12) // 减少水平内边距 (从16到12)
                    .padding(.vertical, 8) // 减少垂直内边距 (从12到8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity) // 确保占用最大可用空间
                    .contentShape(Rectangle()) // 确保整个区域都能响应点击
                    .background(
                        RoundedRectangle(cornerRadius: 8) // 增大圆角
                            .fill(selectedTab == tab ? Color.accentColor : Color.clear)
                    )
                    .foregroundColor(selectedTab == tab ? .white : .primary)
                }
                .buttonStyle(.plain) // 使用plain样式确保没有默认的按钮行为干扰
                .frame(maxWidth: .infinity) // 确保按钮占用最大宽度
            }
        }
        .frame(height: 60) // 设置固定高度为60像素
        .padding(.horizontal, 8)
        .padding(.vertical, 6) // 减少垂直内边距 (从10到6)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

/// 字幕搜索 Tab 视图
struct SubtitleSearchTabView: View {
    @ObservedObject var viewModel: SearchViewModel
    @State private var currentVideoSearchText = ""
    @State private var currentVideoSearchResults: [SearchResult] = []
    
    var body: some View {
        VStack(spacing: 0) {
            // 搜索栏
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("搜索当前视频字幕...", text: $currentVideoSearchText)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        Task { @MainActor in
                            currentVideoSearchResults = viewModel.searchCurrentVideoSubtitles(currentVideoSearchText)
                        }
                    }
                
                if !currentVideoSearchText.isEmpty {
                    Button(action: { 
                        currentVideoSearchText = ""
                        currentVideoSearchResults = []
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            
            // 字幕文件选择
            if viewModel.currentVideoFile != nil {
                HStack {
                    Text("字幕文件:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let selectedSubtitle = viewModel.selectedSubtitleFile {
                        Text(selectedSubtitle.lastPathComponent)
                            .font(.caption)
                            .foregroundColor(.primary)
                    } else {
                        Text("未选择")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("选择字幕") {
                        viewModel.selectSubtitleFile()
                    }
                    .font(.caption)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            
            Divider()
            
            // 搜索结果列表
            if currentVideoSearchResults.isEmpty && !currentVideoSearchText.isEmpty {
                VStack {
                    Text("未找到匹配的字幕")
                        .foregroundColor(.secondary)
                        .padding()
                    Spacer()
                }
            } else if !currentVideoSearchResults.isEmpty {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(currentVideoSearchResults) { result in
                            SubtitleSearchResultRow(
                                result: result,
                                isSelected: viewModel.selectedResult?.id == result.id
                            ) {
                                viewModel.selectResult(result)
                            }
                        }
                    }
                }
            } else {
                VStack {
                    Image(systemName: "captions.bubble")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    
                    Text("输入关键词搜索字幕")
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding()
            }
        }
    }
}

/// 字幕搜索结果行
struct SubtitleSearchResultRow: View {
    let result: SearchResult
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // 时间标签
            Text(result.formattedTime)
                .font(.system(.caption, design: .monospaced))
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.accentColor.opacity(0.1))
                .foregroundColor(.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 4))
            
            // 字幕内容
            Text(attributedContent)
                .font(.body)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            // 播放图标
            if isSelected || isHovered {
                Image(systemName: isSelected ? "play.circle.fill" : "play.circle")
                    .font(.title3)
                    .foregroundColor(isSelected ? .accentColor : .secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(backgroundColor)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .onTapGesture {
            onTap()
        }
    }
    
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
}

#Preview {
    TabControlView(selectedTab: .constant(.subtitleSearch))
        .frame(width: 400)
}
