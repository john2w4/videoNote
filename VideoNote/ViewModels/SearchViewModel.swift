import Foundation
import SwiftUI
import AVKit
import Combine

/// 搜索视图模型 - 管理应用的主要状态和逻辑
@MainActor
class SearchViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var searchText = ""
    @Published var searchResults: [SearchResult] = []
    @Published var selectedResult: SearchResult?
    @Published var isLoading = false
    @Published var workingDirectory: URL?
    @Published var player: AVPlayer?
    @Published var errorMessage: String?
    @Published var showingExportSheet = false
    
    // MARK: - Search State Persistence
    @Published var savedSearchText = ""
    @Published var savedSearchResults: [SearchResult] = []
    @Published var savedSelectedResult: SearchResult?
    @Published var searchScrollPosition: CGPoint = .zero
    
    // MARK: - New Properties for Enhanced Features
    @Published var videoFiles: [VideoFile] = []
    @Published var noteFiles: [NoteFile] = []
    @Published var currentVideoFile: VideoFile?
    @Published var currentNoteFile: NoteFile?
    @Published var selectedTab: ContentTab = .subtitleSearch
    @Published var noteContent: String = ""
    @Published var editingNoteContent: String = ""
    @Published var currentSubtitles: [SubtitleEntry] = []
    @Published var selectedSubtitleFile: URL?
    @Published var currentSubtitleText: String?
    
    // MARK: - Cursor Position Management
    @Published var cursorPosition: Int = 0
    var textEditorCoordinator: CursorAwareTextEditor.Coordinator?
    
    // MARK: - Auto Save
    @Published var hasUnsavedChanges = false
    @Published var isAutoSaving = false
    @Published var isSeekingVideo = false // 添加视频跳转状态
    private var autoSaveTimer: Timer?
    private let autoSaveInterval: TimeInterval = 5.0 // 5秒自动保存
    
    // MARK: - Export Configuration
    @Published var exportMaxResults = 100
    @Published var exportInterval = 1
    
    // MARK: - Private Properties
    private var subtitleEntries: [SubtitleEntry] = []
    private let directoryScanner = DirectoryScanner()
    private var cancellables = Set<AnyCancellable>()
    
    // 防止死循环的标志位
    private var isLoadingAssociatedFile = false
    
    // 标签状态管理
    private var previousTab: ContentTab = .subtitleSearch
    private let userDefaults = UserDefaults.standard
    private let workingDirectoryKey = "VidSearchWorkingDirectory"
    private var isPerformingSearch = false // 防止搜索死循环
    private var timeObserverToken: Any?
    
    // MARK: - Initialization
    init() {
        setupSearchBinding()
        loadPersistedWorkingDirectory()
        setupPlayerObserver()
        setupAutoSave()
        setupTabChangeObserver()
    }
    
    // MARK: - Tab State Management
    private func setupTabChangeObserver() {
        $selectedTab
            .removeDuplicates()
            .sink { [weak self] newTab in
                self?.handleTabChange(to: newTab)
            }
            .store(in: &cancellables)
    }
    
    private func handleTabChange(to newTab: ContentTab) {
        // 当离开字幕搜索标签时，保存当前状态
        if previousTab == .subtitleSearch && newTab != .subtitleSearch {
            saveSearchState()
        }
        
        // 当进入字幕搜索标签时，恢复之前的状态
        if newTab == .subtitleSearch && previousTab != .subtitleSearch {
            restoreSearchState()
        }
        
        // 更新前一个标签状态
        previousTab = newTab
    }
    
    private func saveSearchState() {
        print("💾 保存搜索状态: 搜索词='\(searchText)', 结果=\(searchResults.count)条")
        savedSearchText = searchText
        savedSearchResults = searchResults
        savedSelectedResult = selectedResult
    }
    
    private func restoreSearchState() {
        // 只有在有保存的状态时才恢复
        if !savedSearchText.isEmpty || !savedSearchResults.isEmpty {
            print("🔄 恢复搜索状态: 搜索词='\(savedSearchText)', 结果=\(savedSearchResults.count)条")
            
            // 临时禁用搜索绑定，避免触发新的搜索
            let oldIsPerformingSearch = isPerformingSearch
            isPerformingSearch = true
            
            searchText = savedSearchText
            searchResults = savedSearchResults
            selectedResult = savedSelectedResult
            
            // 恢复搜索绑定
            isPerformingSearch = oldIsPerformingSearch
        }
    }
    
    // MARK: - Setup Methods
    private func setupSearchBinding() {
        // 搜索文本变化时自动搜索，带去抖动
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] searchText in
                self?.performSearch(searchText)
            }
            .store(in: &cancellables)
    }
    
    private func setupAutoSave() {
        // 监听编辑内容变化
        $editingNoteContent
            .removeDuplicates()
            .sink { [weak self] newContent in
                guard let self = self else { return }
                
                // 检查是否有未保存的更改
                self.hasUnsavedChanges = newContent != self.noteContent
                
                // 重置自动保存定时器
                self.resetAutoSaveTimer()
            }
            .store(in: &cancellables)
    }
    
    private func resetAutoSaveTimer() {
        autoSaveTimer?.invalidate()
        
        // 只有在有未保存更改且有当前笔记文件时才启动定时器
        guard hasUnsavedChanges, currentNoteFile != nil else { return }
        
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: autoSaveInterval, repeats: false) { [weak self] _ in
            Task { @MainActor in
                await self?.performAutoSave()
            }
        }
    }
    
    private func performAutoSave() async {
        guard hasUnsavedChanges, !isAutoSaving else { return }
        
        isAutoSaving = true
        
        do {
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1秒延迟，避免频繁保存
            saveNoteContent()
            print("📝 自动保存完成")
        } catch {
            print("❌ 自动保存失败: \(error)")
        }
        
        isAutoSaving = false
    }
    
    private func loadPersistedWorkingDirectory() {
        if let data = userDefaults.data(forKey: workingDirectoryKey) {
            var isStale = false
            if let url = try? URL(resolvingBookmarkData: data, 
                                  options: .withSecurityScope, 
                                  relativeTo: nil, 
                                  bookmarkDataIsStale: &isStale) {
                _ = url.startAccessingSecurityScopedResource()
                workingDirectory = url
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// 选择工作目录
    func selectWorkingDirectory() {
        let openPanel = NSOpenPanel()
        openPanel.title = "选择视频库目录"
        openPanel.message = "请选择包含视频和字幕文件的根目录"
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = false
        openPanel.allowsMultipleSelection = false
        
        openPanel.begin { [weak self] response in
            guard let self = self, response == .OK, let url = openPanel.url else { return }
            
            Task { @MainActor in
                await self.setWorkingDirectory(url)
            }
        }
    }
    
    /// 设置工作目录并开始扫描
    func setWorkingDirectory(_ url: URL) async {
        guard directoryScanner.validateDirectory(url) else {
            errorMessage = "无法访问选择的目录"
            return
        }
        
        workingDirectory = url
        saveWorkingDirectory(url)
        await scanWorkingDirectory()
    }
    
    /// 扫描工作目录
    func scanWorkingDirectory() async {
        guard let workingDirectory = workingDirectory else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // 扫描字幕文件
            subtitleEntries = try await directoryScanner.scanDirectory(workingDirectory)
            
            // 扫描视频和笔记文件
            await scanMediaFiles(in: workingDirectory)
            
            // 如果当前有搜索文本，重新执行搜索（但要避免死循环）
            if !searchText.isEmpty && !isPerformingSearch {
                performSearch(searchText)
            }
        } catch {
            errorMessage = "扫描目录失败: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// 扫描媒体文件
    private func scanMediaFiles(in directory: URL) async {
        let fileManager = FileManager.default
        
        guard let enumerator = fileManager.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else { return }
        
        var videos: [VideoFile] = []
        var notes: [NoteFile] = []
        
        for case let fileURL as URL in enumerator {
            let pathExtension = fileURL.pathExtension.lowercased()
            
            // 检查视频文件
            if ["mp4", "mov", "mkv", "avi", "m4v", "wmv", "flv"].contains(pathExtension) {
                var videoFile = VideoFile(url: fileURL)
                videoFile.associatedSubtitles = videoFile.findAssociatedSubtitles(in: fileURL.deletingLastPathComponent())
                videoFile.associatedNotes = videoFile.findAssociatedNotes(in: fileURL.deletingLastPathComponent())
                videos.append(videoFile)
            }
            
            // 检查笔记文件
            if ["md", "txt", "markdown"].contains(pathExtension) {
                notes.append(NoteFile(url: fileURL))
            }
        }
        
        videoFiles = videos.sorted { $0.name < $1.name }
        noteFiles = notes.sorted { $0.name < $1.name }
    }
    
    /// 执行搜索
    private func performSearch(_ query: String) {
        // 防止搜索死循环
        guard !isPerformingSearch else { return }
        isPerformingSearch = true
        
        defer { isPerformingSearch = false }
        
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        // 解析多个搜索词
        let searchTerms = parseSearchTerms(query)
        print("🔍 搜索词解析: \(searchTerms)")
        
        let results = subtitleEntries
            .filter { entry in
                // 只要匹配任意一个搜索词就返回true
                searchTerms.contains { term in
                    entry.content.localizedCaseInsensitiveContains(term)
                }
            }
            .map { entry in
                SearchResult(subtitleEntry: entry, searchKeyword: query)
            }
            .sorted { result1, result2 in
                // 按时间排序
                result1.subtitleEntry.startTime < result2.subtitleEntry.startTime
            }
        
        searchResults = results
    }
    
    /// 解析搜索词，支持中英文逗号分隔
    private func parseSearchTerms(_ query: String) -> [String] {
        // 支持中文逗号（，）和英文逗号（,）分隔
        let separators = CharacterSet(charactersIn: ",，")
        
        return query
            .components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    
    /// 获取当前搜索词数量
    var searchTermsCount: Int {
        guard !searchText.isEmpty else { return 0 }
        return parseSearchTerms(searchText).count
    }
    
    /// 选择搜索结果并播放视频
    func selectResult(_ result: SearchResult) {
        selectedResult = result
        
        // 查找对应的视频文件
        guard let videoURL = findVideoURL(for: result.subtitleEntry.sourceFilePath) else {
            self.errorMessage = "找不到与字幕匹配的视频文件"
            return
        }
        
        let wasPlaying = player?.rate != 0
        let targetTime = CMTime(seconds: result.subtitleEntry.startTime, preferredTimescale: 600)
        
        let playerToUse: AVPlayer
        
        // 如果当前播放的视频和目标视频是同一个，则复用播放器
        if let currentPlayer = player, (currentPlayer.currentItem?.asset as? AVURLAsset)?.url == videoURL {
            playerToUse = currentPlayer
        } else {
            playerToUse = AVPlayer(url: videoURL)
            self.player = playerToUse
            setupPlayerObserver() // 为新播放器设置观察者
        }
        
        // 跳转到指定时间，并在完成后根据之前的状态决定是否播放
        playerToUse.seek(to: targetTime) { finished in
            if finished {
                if wasPlaying {
                    Task { @MainActor in
                        playerToUse.play()
                    }
                }
            }
        }
    }
    
    private func findVideoURL(for subtitleURL: URL) -> URL? {
        let videoExtensions = ["mp4", "mov", "mkv", "avi", "m4v", "wmv", "flv"]
        let baseName = subtitleURL.deletingPathExtension().lastPathComponent

        // 查找所有视频文件
        for videoFile in videoFiles {
            let videoBaseName = videoFile.url.deletingPathExtension().lastPathComponent
            if videoBaseName == baseName {
                return videoFile.url
            }
        }

        // 如果没有找到，尝试在同一个目录中查找
        let directory = subtitleURL.deletingLastPathComponent()
        for ext in videoExtensions {
            let videoURL = directory.appendingPathComponent(baseName).appendingPathExtension(ext)
            if FileManager.default.fileExists(atPath: videoURL.path) {
                return videoURL
            }
        }

        return nil
    }
    
    // MARK: - Player Control
    
    /// 切换播放/暂停状态
    func togglePlayPause() {
        guard let player = player else { return }
        if player.rate == 0 {
            player.play()
        } else {
            player.pause()
        }
    }
    
    /// 后退指定秒数
    func rewind(by seconds: TimeInterval) {
        guard let player = player else { 
            print("⚠️ 后退失败: 播放器不存在")
            return 
        }
        
        let currentTime = player.currentTime()
        guard currentTime.isValid else {
            print("⚠️ 后退失败: 当前时间无效")
            return
        }
        
        let wasPlaying = player.rate > 0
        let newTime = CMTimeSubtract(currentTime, CMTime(seconds: seconds, preferredTimescale: 600))
        let boundedTime = CMTimeMaximum(newTime, CMTime.zero) // 确保不会倒退到负时间
        
        print("⏪ 后退 \(seconds) 秒: \(CMTimeGetSeconds(currentTime)) → \(CMTimeGetSeconds(boundedTime))")
        
        player.seek(to: boundedTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero) { finished in
            DispatchQueue.main.async {
                if finished {
                    print("✅ 后退完成")
                    if wasPlaying {
                        player.play()
                    }
                } else {
                    print("❌ 后退未完成")
                }
            }
        }
    }
    
    /// 快进指定秒数
    func fastForward(by seconds: TimeInterval) {
        guard let player = player else { 
            print("⚠️ 快进失败: 播放器不存在")
            return 
        }
        
        let currentTime = player.currentTime()
        guard currentTime.isValid else {
            print("⚠️ 快进失败: 当前时间无效")
            return
        }
        
        let wasPlaying = player.rate > 0
        let newTime = CMTimeAdd(currentTime, CMTime(seconds: seconds, preferredTimescale: 600))
        
        // 检查是否超过视频总时长
        var boundedTime = newTime
        if let duration = player.currentItem?.duration, duration.isValid {
            boundedTime = CMTimeMinimum(newTime, duration)
        }
        
        print("⏩ 快进 \(seconds) 秒: \(CMTimeGetSeconds(currentTime)) → \(CMTimeGetSeconds(boundedTime))")
        
        player.seek(to: boundedTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero) { finished in
            DispatchQueue.main.async {
                if finished {
                    print("✅ 快进完成")
                    if wasPlaying {
                        player.play()
                    }
                } else {
                    print("❌ 快进未完成")
                }
            }
        }
    }
    
    // MARK: - Player Control

    
    /// 导出搜索结果
    func exportResults() {
        guard !searchResults.isEmpty else {
            errorMessage = "没有搜索结果可导出"
            return
        }
        
        let configuration = MarkdownExporter.ExportConfiguration(
            maxResults: exportMaxResults,
            interval: exportInterval,
            searchKeyword: searchText
        )
        
        let defaultFileName = "VidSearch_\(searchText)_\(DateFormatter.fileNameFormatter.string(from: Date())).md"
        
        MarkdownExporter.showSaveDialog(defaultName: defaultFileName) { [weak self] url in
            guard let self = self, let saveURL = url else { return }
            
            Task { @MainActor in
                do {
                    try MarkdownExporter.exportToMarkdown(
                        searchResults: self.searchResults,
                        configuration: configuration,
                        saveURL: saveURL
                    )
                } catch {
                    self.errorMessage = "导出失败: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // MARK: - Private Methods
    private func saveWorkingDirectory(_ url: URL) {
        do {
            let bookmarkData = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            userDefaults.set(bookmarkData, forKey: workingDirectoryKey)
        } catch {
            print("保存工作目录失败: \(error)")
        }
    }
    
    /// 清除错误信息
    func clearError() {
        errorMessage = nil
    }
    var resultsCount: String {
        if searchText.isEmpty {
            return "输入关键词开始搜索"
        } else if searchResults.isEmpty {
            return "未找到匹配结果"
        } else {
            return "找到 \(searchResults.count) 条结果"
        }
    }
    
    /// 检查是否已设置工作目录
    var hasWorkingDirectory: Bool {
        workingDirectory != nil
    }
    
    // MARK: - New Methods for Enhanced Features
    
    /// 选择视频文件
    func selectVideoFile(_ videoFile: VideoFile) {
        // 防止死循环
        guard !isLoadingAssociatedFile else {
            print("⚠️ 检测到递归调用，跳过视频文件选择")
            return
        }
        
        // 停止当前正在播放的视频
        if let currentPlayer = player {
            currentPlayer.pause()
            currentPlayer.seek(to: .zero)
            print("⏸️ 停止当前视频播放")
        }
        
        currentVideoFile = videoFile
        
        // 加载视频到播放器
        let playerItem = AVPlayerItem(url: videoFile.url)
        player = AVPlayer(playerItem: playerItem)
        print("🎬 加载新视频: \(videoFile.name)")
        
        // 自动播放视频
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.player?.play()
            print("▶️ 自动开始播放视频")
        }
        
        // 自动加载字幕
        loadSubtitlesForCurrentVideo()
        
        // 自动关联笔记 - 优先查找同名的md文件
        if !isLoadingAssociatedFile {
            autoLoadAssociatedNote(for: videoFile)
        }
    }
    
    /// 自动加载关联的笔记文件
    private func autoLoadAssociatedNote(for videoFile: VideoFile) {
        // 防止递归调用
        guard !isLoadingAssociatedFile else {
            print("⚠️ 检测到递归调用，跳过笔记文件自动关联")
            return
        }
        
        isLoadingAssociatedFile = true
        defer { isLoadingAssociatedFile = false }
        
        let videoBaseName = videoFile.url.deletingPathExtension().lastPathComponent
        let expectedNoteName = "\(videoBaseName).md"
        
        // 首先查找同名的md笔记文件
        if let sameNameNote = noteFiles.first(where: { $0.url.lastPathComponent == expectedNoteName }) {
            print("📖 找到同名笔记文件: \(expectedNoteName)")
            selectNoteFile(sameNameNote)
            return
        }
        
        // 如果没有找到同名笔记，查找其他关联的笔记
        if let associatedNote = videoFile.associatedNotes.first {
            print("📖 找到关联笔记文件: \(associatedNote.lastPathComponent)")
            selectNoteFile(noteFiles.first { $0.url == associatedNote })
            return
        }
        
        // 如果都没有找到，清空当前笔记选择
        print("📖 未找到关联笔记文件，清空选择")
        selectNoteFile(nil)
    }
    
    /// 选择笔记文件
    func selectNoteFile(_ noteFile: NoteFile?) {
        // 清空之前的定时器
        autoSaveTimer?.invalidate()
        autoSaveTimer = nil
        
        currentNoteFile = noteFile
        
        if let noteFile = noteFile {
            // 加载笔记内容
            do {
                var mutableNoteFile = noteFile
                try mutableNoteFile.loadContent()
                noteContent = mutableNoteFile.content
                editingNoteContent = mutableNoteFile.content
                hasUnsavedChanges = false
                
                // 更新 noteFiles 中的内容
                if let index = noteFiles.firstIndex(where: { $0.id == noteFile.id }) {
                    noteFiles[index] = mutableNoteFile
                }
            } catch {
                errorMessage = "加载笔记失败: \(error.localizedDescription)"
            }
            
            // 自动关联视频 - 添加递归保护
            if !isLoadingAssociatedFile {
                isLoadingAssociatedFile = true
                defer { isLoadingAssociatedFile = false }
                
                if let associatedVideo = noteFile.findAssociatedVideo(in: noteFile.url.deletingLastPathComponent()) {
                    if let videoFile = videoFiles.first(where: { $0.url == associatedVideo }) {
                        selectVideoFile(videoFile)
                    }
                }
            }
        } else {
            // 清空编辑器
            noteContent = ""
            editingNoteContent = ""
            hasUnsavedChanges = false
        }
    }
    
    /// 创建新的笔记文件
    func createNewNote(in directory: URL? = nil) {
        let fileName: String
        let videoName: String
        let targetDirectory: URL
        
        if let currentVideo = currentVideoFile {
            // 如果有当前视频，在视频文件的同一目录下创建笔记
            targetDirectory = currentVideo.url.deletingLastPathComponent()
            let videoBaseName = currentVideo.url.deletingPathExtension().lastPathComponent
            fileName = "\(videoBaseName).md"
            videoName = currentVideo.name
            print("📝 在视频同目录创建笔记: \(targetDirectory.path)/\(fileName)")
        } else {
            // 如果没有当前视频，使用指定目录或工作目录
            targetDirectory = directory ?? workingDirectory ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
            let timestamp = dateFormatter.string(from: Date())
            fileName = "笔记_\(timestamp).md"
            videoName = "未关联视频"
            print("📝 在指定目录创建笔记: \(targetDirectory.path)/\(fileName)")
        }
        
        let fileURL = targetDirectory.appendingPathComponent(fileName)
        
        // 检查文件是否已存在
        if FileManager.default.fileExists(atPath: fileURL.path) {
            // 如果文件已存在，直接选择它
            Task {
                await scanWorkingDirectory()
                if let existingNoteFile = noteFiles.first(where: { $0.url == fileURL }) {
                    selectNoteFile(existingNoteFile)
                    selectedTab = .noteEdit
                }
            }
            return
        }
        
        do {
            // 创建基于视频的 markdown 文件
            let creationDateFormatter = DateFormatter()
            creationDateFormatter.dateStyle = .long
            creationDateFormatter.timeStyle = .medium
            creationDateFormatter.locale = Locale(identifier: "zh_CN")
            
            let initialContent = """
# \(currentVideoFile?.url.deletingPathExtension().lastPathComponent ?? "新笔记")

**视频文件:** \(videoName)  
**创建时间:** \(creationDateFormatter.string(from: Date()))

---

## 笔记内容

请在这里开始编写您的笔记...

## 重要片段

### 时间戳记录

可以使用截图功能在此处插入视频截图和时间戳链接。

---

"""
            try initialContent.write(to: fileURL, atomically: true, encoding: String.Encoding.utf8)
            
            print("📝 创建笔记文件: \(fileName)")
            
            // 重新扫描目录以更新文件列表
            Task {
                await scanWorkingDirectory()
                
                // 自动选择新创建的笔记
                if let newNoteFile = noteFiles.first(where: { $0.url == fileURL }) {
                    selectNoteFile(newNoteFile)
                    selectedTab = .noteEdit
                }
            }
        } catch {
            errorMessage = "创建笔记失败: \(error.localizedDescription)"
        }
    }
    
    /// 加载当前视频的字幕
    private func loadSubtitlesForCurrentVideo() {
        guard let videoFile = currentVideoFile else { 
            print("❌ 没有当前视频文件")
            return 
        }
        
        print("🎬 尝试为视频 \(videoFile.name) 加载字幕")
        print("📁 关联的字幕文件数量: \(videoFile.associatedSubtitles.count)")
        
        for subtitle in videoFile.associatedSubtitles {
            print("📄 字幕文件: \(subtitle.path)")
        }
        
        if let firstSubtitle = videoFile.associatedSubtitles.first {
            print("✅ 选择第一个字幕文件: \(firstSubtitle.path)")
            selectedSubtitleFile = firstSubtitle
            loadSubtitleFile(firstSubtitle)
        } else {
            print("⚠️ 没有找到关联的字幕文件")
        }
    }
    
    /// 加载字幕文件
    func loadSubtitleFile(_ subtitleURL: URL) {
        print("🎬 尝试加载字幕文件: \(subtitleURL.path)")
        print("📄 文件格式: \(subtitleURL.pathExtension)")
        do {
            let subtitles = try SubtitleParserFactory.parse(fileURL: subtitleURL)
            print("✅ 字幕加载成功，共 \(subtitles.count) 条字幕")
            currentSubtitles = subtitles
            selectedSubtitleFile = subtitleURL
            
            // 打印前3条字幕内容作为验证
            for (index, subtitle) in subtitles.prefix(3).enumerated() {
                print("字幕 \(index + 1): \(subtitle.startTime)s-\(subtitle.endTime)s: \(subtitle.content)")
            }
        } catch {
            let errorMsg = "加载字幕失败: \(error.localizedDescription)"
            print("❌ \(errorMsg)")
            errorMessage = errorMsg
        }
    }
    
    /// 获取当前视频的所有可用字幕文件
    func getAvailableSubtitleFiles() -> [URL] {
        guard let videoFile = currentVideoFile else { return [] }
        return videoFile.associatedSubtitles
    }
    
    /// 选择指定的字幕文件（用于下拉菜单选择）
    func selectSpecificSubtitleFile(_ subtitleURL: URL) {
        print("🎯 选择字幕文件: \(subtitleURL.lastPathComponent)")
        loadSubtitleFile(subtitleURL)
        
        // 选择字幕后，重新执行搜索以更新搜索数据
        if !searchText.isEmpty {
            print("🔄 重新执行搜索以更新字幕数据")
            performSearch(searchText)
        }
    }
    
    /// 手动选择字幕文件
    func selectSubtitleFile() {
        let openPanel = NSOpenPanel()
        openPanel.title = "选择字幕文件"
        openPanel.allowedContentTypes = [
            .init(filenameExtension: "srt")!, 
            .init(filenameExtension: "vtt")!,
            .init(filenameExtension: "ass")!,
            .init(filenameExtension: "ssa")!
        ]
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        
        openPanel.begin { [weak self] response in
            guard let self = self, response == .OK, let url = openPanel.url else { return }
            
            Task { @MainActor in
                print("🎯 用户选择字幕文件: \(url.path)")
                self.loadSubtitleFile(url)
                
                // 选择字幕后，重新执行搜索以更新搜索数据
                if !self.searchText.isEmpty {
                    print("🔄 重新执行搜索以更新字幕数据")
                    self.performSearch(self.searchText)
                }
            }
        }
    }
    
    /// 保存笔记内容
    func saveNoteContent() {
        guard let noteFile = currentNoteFile else { return }
        
        do {
            try noteFile.saveContent(editingNoteContent)
            noteContent = editingNoteContent
            hasUnsavedChanges = false
            
            // 停止自动保存定时器
            autoSaveTimer?.invalidate()
            autoSaveTimer = nil
            
            print("📝 笔记保存成功: \(noteFile.name)")
        } catch {
            errorMessage = "保存笔记失败: \(error.localizedDescription)"
            print("❌ 保存笔记失败: \(error)")
        }
    }
    
    /// 截图功能
    func takeSnapshot() async {
        guard let player = player,
              let currentItem = player.currentItem,
              let videoFile = currentVideoFile else {
            errorMessage = "无法截图：没有正在播放的视频"
            return
        }
        
        let currentTime = player.currentTime()
        let timestamp = CMTimeGetSeconds(currentTime)
        
        // 生成截图
        do {
            let asset = currentItem.asset
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            
            let cgImage = try await imageGenerator.image(at: currentTime).image
            
            // 在当前工作目录下创建images目录保存截图
            let imagesPath: URL
            if let workingDirectory = self.workingDirectory {
                imagesPath = workingDirectory.appendingPathComponent("images")
            } else {
                // 如果没有工作目录，使用文档目录
                let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                imagesPath = documentsPath.appendingPathComponent("images")
            }
            
            // 创建images目录
            try? FileManager.default.createDirectory(at: imagesPath, withIntermediateDirectories: true)
            
            // 生成唯一的文件名
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
            let dateString = dateFormatter.string(from: Date())
            
            // 格式化时间戳
            let hours = Int(timestamp) / 3600
            let minutes = Int(timestamp) % 3600 / 60
            let seconds = Int(timestamp) % 60
            let formattedTimestamp = String(format: "%02d_%02d_%02d", hours, minutes, seconds)
            
            let filename = "\(videoFile.name)_\(formattedTimestamp)_\(dateString).png"
            let imageURL = imagesPath.appendingPathComponent(filename)
            
            let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
            if let imageData = nsImage.tiffRepresentation,
               let bitmapRep = NSBitmapImageRep(data: imageData),
               let pngData = bitmapRep.representation(using: .png, properties: [:]) {
                try pngData.write(to: imageURL)
            }
            
            // 获取当前字幕和上下文
            let currentSubtitle = getCurrentSubtitle(at: timestamp)
            let contextSubtitles = getContextSubtitles(around: timestamp)
            
            // 创建截图模型
            let snapshot = VideoSnapshot(
                imageURL: imageURL,
                timestamp: timestamp,
                videoURL: videoFile.url,
                subtitleText: currentSubtitle?.content ?? "",
                contextSubtitles: contextSubtitles.map { $0.content }
            )
            
            // 在编辑器中插入截图
            insertSnapshotIntoNote(snapshot)
            
        } catch {
            errorMessage = "截图失败: \(error.localizedDescription)"
        }
    }
    
    /// 获取当前时间的字幕
    private func getCurrentSubtitle(at timestamp: TimeInterval) -> SubtitleEntry? {
        return currentSubtitles.first { subtitle in
            timestamp >= subtitle.startTime && timestamp <= subtitle.endTime
        }
    }
    
    /// 获取上下文字幕
    private func getContextSubtitles(around timestamp: TimeInterval, context: Int = 2) -> [SubtitleEntry] {
        guard let currentIndex = currentSubtitles.firstIndex(where: { subtitle in
            timestamp >= subtitle.startTime && timestamp <= subtitle.endTime
        }) else { return [] }
        
        let startIndex = max(0, currentIndex - context)
        let endIndex = min(currentSubtitles.count - 1, currentIndex + context)
        
        return Array(currentSubtitles[startIndex...endIndex])
    }
    
    /// 在笔记中插入截图
    private func insertSnapshotIntoNote(_ snapshot: VideoSnapshot) {
        let markdownInsert = snapshot.generateMarkdownInsert()
        
        // 使用自定义文本编辑器的协调器在光标位置插入
        if let coordinator = textEditorCoordinator {
            coordinator.insertText(markdownInsert)
        } else {
            // 后备方案：在当前光标位置插入
            let insertionIndex = min(cursorPosition, editingNoteContent.count)
            let startIndex = editingNoteContent.index(editingNoteContent.startIndex, offsetBy: insertionIndex)
            editingNoteContent.insert(contentsOf: markdownInsert, at: startIndex)
        }
        
        // 通知内容已更新
        NotificationCenter.default.post(name: .init("NoteContentUpdated"), object: nil)
    }
    
    /// 更新光标位置
    func updateCursorPosition(_ position: Int) {
        cursorPosition = position
    }
    
    /// 设置文本编辑器协调器
    func setTextEditorCoordinator(_ coordinator: CursorAwareTextEditor.Coordinator) {
        textEditorCoordinator = coordinator
    }
    
    /// 处理时间戳链接点击
    func handleTimestampClick(_ timestamp: TimeInterval, videoFileName: String? = nil) {
        // 如果指定了视频文件名或路径，尝试切换到对应的视频
        if let videoIdentifier = videoFileName {
            // 先尝试按文件名匹配
            var targetVideo = videoFiles.first { $0.url.lastPathComponent == videoIdentifier }
            
            // 如果没找到，尝试按完整路径匹配
            if targetVideo == nil {
                targetVideo = videoFiles.first { $0.url.path == videoIdentifier }
            }
            
            // 如果还没找到，尝试按路径的最后部分匹配
            if targetVideo == nil {
                let identifierPath = URL(fileURLWithPath: videoIdentifier).lastPathComponent
                targetVideo = videoFiles.first { $0.url.lastPathComponent == identifierPath }
            }
            
            if let targetVideo = targetVideo {
                if currentVideoFile?.id != targetVideo.id {
                    print("🔄 切换到视频: \(videoIdentifier)")
                    selectVideoFile(targetVideo)
                    
                    // 延迟执行跳转，确保视频已加载
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.performTimestampSeek(timestamp)
                    }
                    return
                }
            } else {
                errorMessage = "未找到对应的视频文件: \(videoIdentifier)"
                return
            }
        }
        
        // 执行时间戳跳转
        performTimestampSeek(timestamp)
    }
    
    /// 执行时间戳跳转
    private func performTimestampSeek(_ timestamp: TimeInterval) {
        guard let player = player else { 
            errorMessage = "无法跳转：没有加载的视频播放器"
            return 
        }
        
        guard !isSeekingVideo else {
            print("⏳ 正在跳转中，请稍候...")
            return
        }
        
        // 检查当前播放的视频时长，确保时间戳不超出范围
        if let currentItem = player.currentItem {
            let duration = CMTimeGetSeconds(currentItem.duration)
            if !duration.isNaN && !duration.isInfinite && timestamp > duration {
                errorMessage = "时间戳超出视频范围：\(formatTime(timestamp)) > \(formatTime(duration))"
                return
            }
        }
        
        print("🎯 跳转到时间戳: \(formatTime(timestamp))")
        isSeekingVideo = true
        
        // 获取跳转前的播放状态
        let wasPlaying = player.rate > 0
        
        let cmTime = CMTime(seconds: timestamp, preferredTimescale: 600)
        
        // 使用精确跳转，并在跳转完成后恢复播放状态
        player.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero) { completed in
            Task { @MainActor in
                self.isSeekingVideo = false
                
                if completed {
                    // 恢复之前的播放状态，或者强制播放
                    if wasPlaying || true { // 总是播放，因为用户点击了时间戳
                        self.player?.play()
                    }
                    print("✅ 视频跳转到 \(self.formatTime(timestamp)) 并开始播放")
                    
                    // 自动切换到视频播放tab（如果需要的话）
                    // self.selectedTab = .videoPlayer  // 可以根据需要启用
                } else {
                    self.errorMessage = "视频跳转失败"
                    print("❌ 视频跳转失败")
                }
            }
        }
    }
    
    /// 格式化时间为 HH:MM:SS 格式
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) % 3600 / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    /// 搜索当前视频字幕
    func searchCurrentVideoSubtitles(_ query: String) -> [SearchResult] {
        guard !query.isEmpty else { return [] }
        
        return currentSubtitles
            .filter { $0.content.localizedCaseInsensitiveContains(query) }
            .map { SearchResult(subtitleEntry: $0, searchKeyword: query) }
            .sorted { $0.subtitleEntry.startTime < $1.subtitleEntry.startTime }
    }
    
    private func setupPlayerObserver() {
        $player
            .sink { [weak self] newPlayer in
                guard let self = self else { return }
                
                // 移除旧的观察者
                if let token = self.timeObserverToken {
                    self.player?.removeTimeObserver(token)
                    self.timeObserverToken = nil
                }
                
                // 为新播放器添加时间观察者
                guard let player = newPlayer else { return }
                
                let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
                self.timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
                    Task { @MainActor in
                        self?.updateCurrentSubtitle(at: time)
                    }
                }
            }
            .store(in: &cancellables)
    }

    private func updateCurrentSubtitle(at time: CMTime) {
        let currentTime = time.seconds
        
        // 查找当前时间的字幕
        let subtitle = currentSubtitles.first { entry in
            currentTime >= entry.startTime && currentTime <= entry.endTime
        }
        
        // 更新字幕文本
        if currentSubtitleText != subtitle?.content {
            currentSubtitleText = subtitle?.content
        }
    }
    
    // MARK: - Directory Operations
    
    /// 打开笔记文件所在目录
    func openNoteDirectory() {
        guard let currentNote = currentNoteFile else { return }
        let directoryURL = currentNote.url.deletingLastPathComponent()
        NSWorkspace.shared.open(directoryURL)
    }
    
    /// 打开指定笔记文件所在目录
    func openNoteDirectory(for noteFile: NoteFile) {
        let directoryURL = noteFile.url.deletingLastPathComponent()
        NSWorkspace.shared.open(directoryURL)
    }
    
    /// 在Finder中选中指定的笔记文件
    func revealNoteFileInFinder(for noteFile: NoteFile) {
        NSWorkspace.shared.activateFileViewerSelecting([noteFile.url])
    }
    
    // MARK: - Application Lifecycle
    
    /// 应用退出前的清理工作
    func prepareForExit() {
        print("🚪 准备退出应用，执行清理工作...")
        
        // 1. 停止视频播放
        if let player = self.player {
            player.pause()
            player.replaceCurrentItem(with: nil)
            print("⏹️ 视频播放已停止")
        }
        
        // 2. 保存未保存的笔记内容
        if hasUnsavedChanges {
            saveNoteContent()
            print("💾 未保存的笔记内容已保存")
        }
        
        // 3. 清理定时器和观察者
        autoSaveTimer?.invalidate()
        autoSaveTimer = nil
        
        // 4. 清理其他资源
        self.player = nil
        print("✅ 应用清理完成")
    }
}

// MARK: - DateFormatter Extension
extension DateFormatter {
    static let fileNameFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter
    }()
}
