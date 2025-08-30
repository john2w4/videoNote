import SwiftUI

/// 搜索界面视图
struct SearchView: View {
    @ObservedObject var viewModel: SearchViewModel
    @State private var scrollPosition: Int? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // 搜索栏
            searchHeader
                .padding(.bottom, 4) // 减少间距以节省空间
            
            // 结果统计
            resultsSummary
            
            Divider()
            
            // 搜索结果列表
            if viewModel.isLoading {
                loadingView
            } else if viewModel.hasWorkingDirectory {
                searchResultsList
                    .frame(maxWidth: .infinity, maxHeight: .infinity) // 确保列表占用最大空间
            } else {
                welcomeView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) // 确保整个视图占用最大空间
        .background(Color(NSColor.controlBackgroundColor))
        .onReceive(viewModel.$selectedTab) { tab in
            // 当切换到搜索标签页时，尝试恢复滚动位置
            if tab == .subtitleSearch && !viewModel.searchResults.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if let selected = viewModel.selectedResult,
                       let index = viewModel.searchResults.firstIndex(where: { $0.id == selected.id }) {
                        scrollPosition = index
                    }
                }
            }
        }
    }
    
    // MARK: - Search Header
    private var searchHeader: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("输入搜索关键词（支持多个词，用,或，分隔）...", text: $viewModel.searchText)
                    .textFieldStyle(.roundedBorder)
                    .disabled(!viewModel.hasWorkingDirectory || viewModel.isLoading)
                
                if !viewModel.searchText.isEmpty {
                    Button(action: { viewModel.searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // 字幕选择组件
            subtitleSelectionView
            
            if let workingDirectory = viewModel.workingDirectory {
                HStack {
                    Image(systemName: "folder")
                        .foregroundColor(.secondary)
                    
                    Text(workingDirectory.lastPathComponent)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    Spacer()
                }
            }
        }
        .padding()
    }
    
    // MARK: - Subtitle Selection
    private var subtitleSelectionView: some View {
        VStack(spacing: 8) {
            if viewModel.currentVideoFile != nil {
                HStack {
                    Image(systemName: "text.quote")
                        .foregroundColor(.secondary)
                    
                    Text("字幕文件:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("选择文件") {
                        viewModel.selectSubtitleFile()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                }
                
                // 显示可用字幕文件的下拉选择
                let availableSubtitles = viewModel.getAvailableSubtitleFiles()
                if !availableSubtitles.isEmpty {
                    HStack {
                        Text("可用字幕:")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Picker("选择字幕", selection: Binding<URL?>(
                            get: { viewModel.selectedSubtitleFile },
                            set: { if let url = $0 { viewModel.selectSpecificSubtitleFile(url) } }
                        )) {
                            Text("无").tag(nil as URL?)
                            ForEach(availableSubtitles, id: \.self) { subtitle in
                                Text(subtitle.lastPathComponent)
                                    .tag(subtitle as URL?)
                            }
                        }
                        .pickerStyle(.menu)
                        .controlSize(.mini)
                        
                        Spacer()
                    }
                }
                
                // 显示当前选中的字幕文件
                if let selectedSubtitle = viewModel.selectedSubtitleFile {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        
                        Text(selectedSubtitle.lastPathComponent)
                            .font(.caption2)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text("\(viewModel.currentSubtitles.count) 条字幕")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    // MARK: - Results Summary
    private var resultsSummary: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.resultsCount)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if viewModel.searchTermsCount > 1 {
                    Text("使用了 \(viewModel.searchTermsCount) 个搜索词")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
            
            if !viewModel.searchResults.isEmpty {
                Text("点击结果播放视频")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("正在扫描视频目录...")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("请稍候，正在建立字幕索引")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Welcome View
    private var welcomeView: some View {
        VStack(spacing: 20) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 50))
                .foregroundColor(.accentColor)
            
            Text("欢迎使用 VidSearch")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("请先选择包含视频和字幕文件的目录")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // 显示支持的视频格式
            Text(viewModel.getVideoFormatInfo())
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
                .multilineTextAlignment(.center)
            
            Button("选择目录") {
                viewModel.selectWorkingDirectory()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Search Results List
    private var searchResultsList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 1) {
                    ForEach(Array(viewModel.searchResults.enumerated()), id: \.element.id) { index, result in
                        SearchResultRow(
                            result: result,
                            isSelected: viewModel.selectedResult?.id == result.id
                        ) {
                            viewModel.selectResult(result)
                            // 保存当前选中项的位置
                            scrollPosition = index
                        }
                        .id(index)
                    }
                }
            }
            .background(Color(NSColor.controlBackgroundColor))
            .onChange(of: scrollPosition) { position in
                if let position = position {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo(position, anchor: .center)
                    }
                }
            }
            .onAppear {
                // 视图出现时尝试恢复滚动位置
                if let selected = viewModel.selectedResult,
                   let index = viewModel.searchResults.firstIndex(where: { $0.id == selected.id }) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        scrollPosition = index
                    }
                }
            }
        }
    }
}

#Preview {
    SearchView(viewModel: SearchViewModel())
        .frame(width: 350, height: 500)
}
