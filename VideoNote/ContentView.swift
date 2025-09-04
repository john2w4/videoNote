import SwiftUI
import AVKit
import AppKit

/// 应用主内容视图
struct ContentView: View {
    @EnvironmentObject var searchViewModel: SearchViewModel
    @State private var showingDirectoryPicker = false
    @State private var keyMonitor: Any?
    
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
                setupKeyboardHandling()
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
        .onDisappear {
            // 清理键盘监听器
            if let keyMonitor = keyMonitor {
                NSEvent.removeMonitor(keyMonitor)
            }
        }
    }
    
    /// 设置键盘事件处理
    private func setupKeyboardHandling() {
        // 移除现有的监听器
        if let keyMonitor = keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
        }
        
        print("设置键盘监听器...")
        
        // 添加本地键盘监听器
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            print("键盘事件 - keyCode: \(event.keyCode), modifiers: \(event.modifierFlags)")
            
            // 检查是否是空格键且没有修饰键
            if event.keyCode == 49 && event.modifierFlags.intersection(.deviceIndependentFlagsMask).isEmpty {
                print("检测到空格键按下")
                let textEditorFocused = isTextEditorFocused()
                print("文本编辑器获得焦点: \(textEditorFocused)")
                
                // 只有当前没有文本编辑器获得焦点时才处理空格键
                if !textEditorFocused {
                    print("触发视频播放/暂停")
                    DispatchQueue.main.async {
                        searchViewModel.togglePlayPause()
                    }
                    return nil // 消费这个事件
                } else {
                    print("跳过空格键处理 - 文本编辑器获得焦点")
                }
            }
            // 左箭头键 - 后退5秒
            else if event.keyCode == 123 && event.modifierFlags.intersection(.deviceIndependentFlagsMask).isEmpty {
                print("检测到左箭头键按下")
                if !isTextEditorFocused() {
                    print("触发视频后退")
                    DispatchQueue.main.async {
                        searchViewModel.rewind(by: 5)
                    }
                    return nil
                }
            }
            // 右箭头键 - 快进5秒
            else if event.keyCode == 124 && event.modifierFlags.intersection(.deviceIndependentFlagsMask).isEmpty {
                print("检测到右箭头键按下")
                if !isTextEditorFocused() {
                    print("触发视频快进")
                    DispatchQueue.main.async {
                        searchViewModel.fastForward(by: 5)
                    }
                    return nil
                }
            }
            
            return event // 不消费其他事件
        }
        
        // 同时添加全局监听器作为备用
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            print("全局键盘事件 - keyCode: \(event.keyCode)")
            if event.keyCode == 49 && event.modifierFlags.intersection(.deviceIndependentFlagsMask).isEmpty {
                if !isTextEditorFocused() {
                    print("全局空格键触发视频控制")
                    DispatchQueue.main.async {
                        searchViewModel.togglePlayPause()
                    }
                }
            }
        }
    }
    
    /// 检查是否有文本编辑器获得焦点
    private func isTextEditorFocused() -> Bool {
        guard let window = NSApp.keyWindow,
              let firstResponder = window.firstResponder else {
            print("没有key window或first responder")
            return false
        }
        
        let responderType = String(describing: type(of: firstResponder))
        print("First responder类型: \(responderType)")
        
        // 检查first responder是否是文本编辑器相关的类
        let isTextEditor = firstResponder is NSTextView || 
               firstResponder is NSTextField ||
               responderType.contains("TextEditor") ||
               responderType.contains("TextView")
        
        print("是否为文本编辑器: \(isTextEditor)")
        return isTextEditor
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
