import SwiftUI
import AVKit

/// 应用主内容视图
struct ContentView: View {
    @EnvironmentObject var searchViewModel: SearchViewModel
    @State private var showingDirectoryPicker = false
    
    var body: some View {
        NavigationSplitView {
            // 左侧面板 - 视频播放器
            VStack(spacing: 0) {
                VideoPlayerView(viewModel: searchViewModel)
                    .frame(minWidth: 400, minHeight: 390) // 增加30%高度 (300 * 1.3 = 390)
                
                // 播放器控制栏
                if searchViewModel.currentVideoFile != nil {
                    PlayerControlBar(viewModel: searchViewModel)
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor))
                        .frame(minHeight: 78) // 增加30%高度 (60 * 1.3 = 78)
                }
            }
        } detail: {
            // 右侧面板 - 新的 Tab 界面
            VStack(spacing: 0) {
                // 目录选择区域
                DirectorySelectionView(viewModel: searchViewModel)
                
                Divider()
                
                // Tab 控制
                TabControlView(selectedTab: $searchViewModel.selectedTab)
                    .frame(height: 60) // 设置固定高度为60像素
                
                Divider()
                
                // Tab 内容
                TabContentView(viewModel: searchViewModel)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(minWidth: 400)
        }
        .navigationTitle("VidSearch")
        .onAppear {
            // 确保窗口能够接收键盘事件
            DispatchQueue.main.async {
                NSApp.windows.first?.makeKey()
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                Button("选择目录") {
                    searchViewModel.selectWorkingDirectory()
                }
                .disabled(searchViewModel.isLoading)
            }
            
            ToolbarItemGroup(placement: .primaryAction) {
                if searchViewModel.hasWorkingDirectory {
                    Button("刷新索引") {
                        Task {
                            await searchViewModel.scanWorkingDirectory()
                        }
                    }
                    .disabled(searchViewModel.isLoading)
                }
                
                Button("导出结果") {
                    searchViewModel.showingExportSheet = true
                }
                .disabled(searchViewModel.searchResults.isEmpty)
            }
        }
        .alert("错误", isPresented: .constant(searchViewModel.errorMessage != nil)) {
            Button("确定") {
                searchViewModel.clearError()
            }
        } message: {
            if let errorMessage = searchViewModel.errorMessage {
                Text(errorMessage)
            }
        }
        .sheet(isPresented: $searchViewModel.showingExportSheet) {
            ExportConfigurationView(viewModel: searchViewModel)
        }
        .task {
            // 应用启动时，如果已有工作目录，自动扫描
            if searchViewModel.hasWorkingDirectory {
                await searchViewModel.scanWorkingDirectory()
            }
        }
    }
}

/// 目录选择视图
struct DirectorySelectionView: View {
    @ObservedObject var viewModel: SearchViewModel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if let workingDirectory = viewModel.workingDirectory {
                    Text("工作目录:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(workingDirectory.lastPathComponent)
                        .font(.headline)
                        .lineLimit(1)
                } else {
                    Text("请选择工作目录")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(0.8)
            }
            
            Button("选择目录") {
                viewModel.selectWorkingDirectory()
            }
            .disabled(viewModel.isLoading)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
}

/// Tab 内容视图
struct TabContentView: View {
    @ObservedObject var viewModel: SearchViewModel
    
    var body: some View {
        Group {
            switch viewModel.selectedTab {
            case .subtitleSearch:
                SubtitleSearchTabView(viewModel: viewModel)
            case .notePreview:
                NotePreviewTabView(viewModel: viewModel)
            case .noteEdit:
                NoteEditTabView(viewModel: viewModel)
            case .videoList:
                VideoListTabView(viewModel: viewModel)
            case .noteList:
                NoteListTabView(viewModel: viewModel)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// 播放器控制栏
struct PlayerControlBar: View {
    @ObservedObject var viewModel: SearchViewModel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if let currentVideo = viewModel.currentVideoFile {
                    Text(currentVideo.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    if let currentNote = viewModel.currentNoteFile {
                        Text("笔记: \(currentNote.name)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Button("截图") {
                    Task {
                        await viewModel.takeSnapshot()
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(viewModel.player == nil)
                
                Button("选择字幕") {
                    viewModel.selectSubtitleFile()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(viewModel.currentVideoFile == nil)
            }
        }
    }
}

#Preview {
    ContentView()
        .frame(width: 1000, height: 700)
}

#Preview {
    ContentView()
        .frame(width: 1000, height: 700)
}
