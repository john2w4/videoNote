import SwiftUI
import WebKit

/// 定义日期格式化器
extension DateFormatter {
    static let shortFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}

/// 笔记预览 Tab 视图
struct NotePreviewTabView: View {
    @ObservedObject var viewModel: SearchViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // 头部信息
            if let currentNote = viewModel.currentNoteFile {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(currentNote.name)
                            .font(.headline)
                        
                        Text("最后修改: \(DateFormatter.shortFormatter.string(from: currentNote.lastModified))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        viewModel.openNoteDirectory()
                    }) {
                        Label("打开目录", systemImage: "folder.fill")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    
                    Button("编辑") {
                        viewModel.selectedTab = .noteEdit
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    
                    // 显示视频跳转状态
                    if viewModel.isSeekingVideo {
                        HStack(spacing: 4) {
                            ProgressView()
                                .scaleEffect(0.7)
                            Text("跳转中...")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                }
                .padding()
                
                Divider()
            }
            
            // Markdown 预览
            if !viewModel.noteContent.isEmpty {
                MarkdownPreviewView(
                    content: viewModel.noteContent,
                    baseDirectory: viewModel.workingDirectory
                ) { timestamp, videoFileName in
                    viewModel.handleTimestampClick(timestamp, videoFileName: videoFileName)
                }
                .overlay(
                    // 跳转时的覆盖层
                    Group {
                        if viewModel.isSeekingVideo {
                            Rectangle()
                                .fill(Color.black.opacity(0.1))
                                .overlay(
                                    VStack(spacing: 8) {
                                        ProgressView()
                                            .scaleEffect(1.2)
                                        Text("正在跳转视频...")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                    }
                                    .padding()
                                    .background(Color(.windowBackgroundColor))
                                    .cornerRadius(8)
                                    .shadow(radius: 4)
                                )
                        }
                    }
                )
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    
                    Text("选择一个笔记文件查看内容")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("笔记将以 Markdown 格式预览显示")
                        .font(.body)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) // 确保整个笔记预览视图占用最大空间
    }
}

/// 笔记编辑 Tab 视图
struct NoteEditTabView: View {
    @ObservedObject var viewModel: SearchViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // 头部工具栏
            HStack {
                if let currentNote = viewModel.currentNoteFile {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(currentNote.name)
                            .font(.headline)
                        
                        HStack(spacing: 8) {
                            if viewModel.isAutoSaving {
                                HStack(spacing: 4) {
                                    ProgressView()
                                        .scaleEffect(0.6)
                                    Text("自动保存中...")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                            } else if viewModel.hasUnsavedChanges {
                                Text("有未保存的更改")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            } else {
                                Text("已保存")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Markdown 编辑器")
                            .font(.headline)
                        
                        Text("创建或选择笔记文件开始编辑")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    if viewModel.currentNoteFile == nil {
                        Button("新建笔记") {
                            viewModel.createNewNote()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    } else {
                        Button(action: {
                            viewModel.openNoteDirectory()
                        }) {
                            Label("打开目录", systemImage: "folder.fill")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        
                        Button("截图") {
                            Task {
                                await viewModel.takeSnapshot()
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .disabled(viewModel.player == nil)
                        
                        Button("预览") {
                            viewModel.selectedTab = .notePreview
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        
                        Button("保存") {
                            viewModel.saveNoteContent()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .disabled(!viewModel.hasUnsavedChanges || viewModel.isAutoSaving)
                    }
                }
            }
            .padding()
            
            Divider()
            
            // 编辑器
            if viewModel.currentNoteFile != nil || !viewModel.editingNoteContent.isEmpty {
                CursorAwareTextEditor(
                    text: $viewModel.editingNoteContent,
                    onTextChange: { newText in
                        // 确保 hasUnsavedChanges 状态正确更新
                        viewModel.updateHasUnsavedChanges()
                    },
                    onCursorPositionChange: { position in
                        viewModel.updateCursorPosition(position)
                    },
                    onCoordinatorReady: { coordinator in
                        viewModel.setTextEditorCoordinator(coordinator)
                    }
                )
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    
                    Text("开始编写您的 Markdown 笔记")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 8) {
                        Text("支持的功能:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("• 标准 Markdown 语法")
                            Text("• 视频截图插入")
                            Text("• 时间戳链接")
                            Text("• 每5秒自动保存")
                        }
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    }
                    
                    Button("创建新笔记") {
                        viewModel.createNewNote()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) // 确保整个编辑视图占用最大空间
    }
}

/// 视频列表 Tab 视图
struct VideoListTabView: View {
    @ObservedObject var viewModel: SearchViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // 头部工具栏
            HStack {
                Text("视频文件")
                    .font(.headline)
                
                Spacer()
                
                if let currentVideo = viewModel.currentVideoFile {
                    // 检查是否已有同名笔记
                    let videoBaseName = currentVideo.url.deletingPathExtension().lastPathComponent
                    let expectedNoteName = "\(videoBaseName).md"
                    let hasNote = viewModel.noteFiles.contains { $0.url.lastPathComponent == expectedNoteName }
                    
                    Button(hasNote ? "打开笔记" : "创建笔记") {
                        viewModel.createNewNote()
                        if !hasNote {
                            // 如果是创建新笔记，切换到编辑tab
                            viewModel.selectedTab = .noteEdit
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
            .padding()
            
            Divider()
            
            if viewModel.videoFiles.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "play.rectangle.stack")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    
                    Text("未找到视频文件")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("请选择包含视频文件的目录")
                        .font(.body)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(viewModel.videoFiles) { videoFile in
                            VideoListRow(
                                videoFile: videoFile,
                                isSelected: viewModel.currentVideoFile?.id == videoFile.id
                            ) {
                                viewModel.selectVideoFile(videoFile)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity) // 确保列表占用最大空间
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) // 确保整个视频列表视图占用最大空间
    }
}

/// 笔记列表 Tab 视图
struct NoteListTabView: View {
    @ObservedObject var viewModel: SearchViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // 头部工具栏
            HStack {
                Text("笔记文件")
                    .font(.headline)
                
                Spacer()
                
                if let currentNote = viewModel.currentNoteFile {
                    // 检查是否有对应的视频文件
                    let noteBaseName = currentNote.url.deletingPathExtension().lastPathComponent
                    let hasMatchingVideo = viewModel.videoFiles.contains { video in
                        let videoBaseName = video.url.deletingPathExtension().lastPathComponent
                        return videoBaseName == noteBaseName
                    }
                    
                    if hasMatchingVideo {
                        Button("播放对应视频") {
                            if let matchingVideo = viewModel.videoFiles.first(where: { video in
                                let videoBaseName = video.url.deletingPathExtension().lastPathComponent
                                return videoBaseName == noteBaseName
                            }) {
                                viewModel.selectVideoFile(matchingVideo)
                                // 这里可以在后续版本中添加视频播放功能
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }
                
                Button("新建笔记") {
                    viewModel.createNewNote()
                    viewModel.selectedTab = .noteEdit
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding()
            
            Divider()
            
            if viewModel.noteFiles.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    
                    Text("暂无笔记文件")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("点击\"新建笔记\"创建第一个笔记")
                        .font(.body)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(viewModel.noteFiles) { noteFile in
                            NoteListRow(
                                noteFile: noteFile,
                                isSelected: viewModel.currentNoteFile?.id == noteFile.id,
                                onTap: {
                                    viewModel.selectNoteFile(noteFile)
                                },
                                onOpenDirectory: {
                                    viewModel.openNoteDirectory(for: noteFile)
                                },
                                onRevealInFinder: {
                                    viewModel.revealNoteFileInFinder(for: noteFile)
                                }
                            )
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity) // 确保列表占用最大空间
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) // 确保整个笔记列表视图占用最大空间
    }
}

/// 视频列表行
struct VideoListRow: View {
    let videoFile: VideoFile
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 12) {
            // 视频图标
            Image(systemName: "play.rectangle.fill")
                .font(.title2)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(videoFile.name)
                    .font(.body)
                    .fontWeight(isSelected ? .semibold : .regular)
                
                HStack(spacing: 12) {
                    if !videoFile.associatedSubtitles.isEmpty {
                        Label("\(videoFile.associatedSubtitles.count)", systemImage: "captions.bubble")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    
                    if !videoFile.associatedNotes.isEmpty {
                        Label("\(videoFile.associatedNotes.count)", systemImage: "doc.text")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            Spacer()
            
            if isSelected || isHovered {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "play.circle")
                    .foregroundColor(isSelected ? .green : .blue)
            }
        }
        .padding()
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

/// 笔记列表行
struct NoteListRow: View {
    let noteFile: NoteFile
    let isSelected: Bool
    let onTap: () -> Void
    let onOpenDirectory: () -> Void
    let onRevealInFinder: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 12) {
            // 笔记图标
            Image(systemName: "doc.text.fill")
                .font(.title2)
                .foregroundColor(.orange)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(noteFile.name)
                    .font(.body)
                    .fontWeight(isSelected ? .semibold : .regular)
                
                Text("修改: \(DateFormatter.shortFormatter.string(from: noteFile.lastModified))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isSelected || isHovered {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "doc.text")
                    .foregroundColor(isSelected ? .green : .orange)
            }
        }
        .padding()
        .background(backgroundColor)
        .contextMenu {
            Button(action: {
                onOpenDirectory()
            }) {
                Label("打开所在目录", systemImage: "folder.fill")
            }
            
            Button(action: {
                onRevealInFinder()
            }) {
                Label("在 Finder 中显示", systemImage: "magnifyingglass")
            }
            
            Divider()
            
            Button(action: {
                onTap()
            }) {
                Label("编辑笔记", systemImage: "pencil")
            }
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .onTapGesture {
            onTap()
        }
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
