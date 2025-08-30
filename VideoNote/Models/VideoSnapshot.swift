import Foundation
import CoreMedia

/// 视频截图模型
struct VideoSnapshot: Identifiable {
    let id = UUID()
    let imageURL: URL
    let timestamp: TimeInterval
    let videoURL: URL
    let subtitleText: String
    let contextSubtitles: [String] // 前后字幕内容
    let createdAt: Date
    
    init(imageURL: URL, timestamp: TimeInterval, videoURL: URL, subtitleText: String, contextSubtitles: [String]) {
        self.imageURL = imageURL
        self.timestamp = timestamp
        self.videoURL = videoURL
        self.subtitleText = subtitleText
        self.contextSubtitles = contextSubtitles
        self.createdAt = Date()
    }
    
    /// 格式化时间戳
    var formattedTimestamp: String {
        let hours = Int(timestamp) / 3600
        let minutes = Int(timestamp) % 3600 / 60
        let seconds = Int(timestamp) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    /// 生成 Markdown 插入文本
    func generateMarkdownInsert() -> String {
        // 创建包含视频文件路径和时间戳的链接
        let videoFilePath = videoURL.path
        let timestampLink = "[\(formattedTimestamp)](\(videoFilePath) + \(formattedTimestamp))"
        
        // 生成相对路径的截图引用
        let screenshotFileName = imageURL.lastPathComponent
        let screenshotReference = "![[images/\(screenshotFileName)|\(videoFilePath) + \(formattedTimestamp)]]"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dateString = dateFormatter.string(from: createdAt)
        
        var markdown = "\n\n---\n\n"
        markdown += "## 📸 视频截图 \(timestampLink)\n\n"
        markdown += "*截图时间: \(dateString) | 视频: \(videoURL.lastPathComponent)*\n\n"
        
        // 使用新格式的截图引用和相对路径的图片显示
        markdown += "\(screenshotReference)\n\n"
        markdown += "![视频截图 - \(formattedTimestamp)](images/\(screenshotFileName))\n\n"
        
        if !subtitleText.isEmpty {
            markdown += "### 📝 当前字幕\n\n"
            markdown += "> \(subtitleText)\n\n"
        }
        
        if !contextSubtitles.isEmpty && contextSubtitles.count > 1 {
            markdown += "### 📋 相关字幕\n\n"
            for (index, subtitle) in contextSubtitles.enumerated() {
                let prefix = subtitle == subtitleText ? "**" : ""
                let suffix = subtitle == subtitleText ? "**" : ""
                markdown += "\(index + 1). \(prefix)\(subtitle)\(suffix)\n"
            }
            markdown += "\n"
        }
        
        markdown += "---\n\n"
        
        return markdown
    }
}
