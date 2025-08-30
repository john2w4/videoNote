import Foundation

/// 视频文件模型
struct VideoFile: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    let name: String
    let duration: TimeInterval?
    var associatedSubtitles: [URL] = []
    var associatedNotes: [URL] = []
    
    init(url: URL) {
        self.url = url
        self.name = url.deletingPathExtension().lastPathComponent
        self.duration = nil // 可以后续通过 AVAsset 获取
    }
    
    /// 获取同名的字幕文件
    func findAssociatedSubtitles(in directory: URL) -> [URL] {
        let fileManager = FileManager.default
        let baseName = url.deletingPathExtension().lastPathComponent
        let subtitleExtensions = ["srt", "ass", "ssa", "vtt", "webvtt"]
        
        print("🔍 在目录 \(directory.path) 中查找视频 \(baseName) 的字幕文件")
        
        var subtitles: [URL] = []
        
        for ext in subtitleExtensions {
            let subtitleURL = directory.appendingPathComponent(baseName).appendingPathExtension(ext)
            print("🔎 检查字幕文件: \(subtitleURL.path)")
            if fileManager.fileExists(atPath: subtitleURL.path) {
                print("✅ 找到字幕文件: \(subtitleURL.path)")
                subtitles.append(subtitleURL)
            } else {
                print("❌ 字幕文件不存在: \(subtitleURL.path)")
            }
        }
        
        print("📄 总共找到 \(subtitles.count) 个字幕文件")
        return subtitles
    }
    
    /// 获取同名的笔记文件
    func findAssociatedNotes(in directory: URL) -> [URL] {
        let fileManager = FileManager.default
        let baseName = url.deletingPathExtension().lastPathComponent
        let noteExtensions = ["md", "txt", "markdown"]
        
        var notes: [URL] = []
        
        for ext in noteExtensions {
            let noteURL = directory.appendingPathComponent(baseName).appendingPathExtension(ext)
            if fileManager.fileExists(atPath: noteURL.path) {
                notes.append(noteURL)
            }
        }
        
        return notes
    }
}

/// 笔记文件模型
struct NoteFile: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    let name: String
    var content: String = ""
    var lastModified: Date
    
    init(url: URL) {
        self.url = url
        self.name = url.deletingPathExtension().lastPathComponent
        
        // 获取文件修改时间
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            self.lastModified = attributes[.modificationDate] as? Date ?? Date()
        } catch {
            self.lastModified = Date()
        }
    }
    
    /// 读取笔记内容
    mutating func loadContent() throws {
        self.content = try String(contentsOf: url, encoding: .utf8)
    }
    
    /// 保存笔记内容
    func saveContent(_ newContent: String) throws {
        try newContent.write(to: url, atomically: true, encoding: .utf8)
    }
    
    /// 获取关联的视频文件
    func findAssociatedVideo(in directory: URL) -> URL? {
        let fileManager = FileManager.default
        let baseName = url.deletingPathExtension().lastPathComponent
        let videoExtensions = ["mp4", "mov", "mkv", "avi", "m4v", "wmv", "flv"]
        
        for ext in videoExtensions {
            let videoURL = directory.appendingPathComponent(baseName).appendingPathExtension(ext)
            if fileManager.fileExists(atPath: videoURL.path) {
                return videoURL
            }
        }
        
        return nil
    }
}

/// Tab 枚举
enum ContentTab: String, CaseIterable {
    case subtitleSearch = "字幕搜索"
    case notePreview = "笔记预览"
    case noteEdit = "笔记编辑"
    case videoList = "视频列表"
    case noteList = "笔记列表"
    
    var systemImage: String {
        switch self {
        case .subtitleSearch: return "magnifyingglass"
        case .notePreview: return "doc.text"
        case .noteEdit: return "square.and.pencil"
        case .videoList: return "play.rectangle.stack"
        case .noteList: return "list.bullet.rectangle"
        }
    }
}
