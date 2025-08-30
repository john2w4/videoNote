import Foundation

/// 表示单条字幕条目的数据模型
struct SubtitleEntry: Identifiable, Codable, Hashable {
    let id: UUID
    let startTime: TimeInterval    // 开始时间（秒）
    let endTime: TimeInterval      // 结束时间（秒）
    let content: String           // 字幕内容
    let sourceFilePath: URL       // 源SRT文件路径
    let sequenceNumber: Int       // 字幕序号
    
    init(id: UUID = UUID(), 
         startTime: TimeInterval, 
         endTime: TimeInterval, 
         content: String, 
         sourceFilePath: URL, 
         sequenceNumber: Int) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.content = content
        self.sourceFilePath = sourceFilePath
        self.sequenceNumber = sequenceNumber
    }
    
    /// 格式化时间为 HH:MM:SS 格式
    var formattedStartTime: String {
        let hours = Int(startTime) / 3600
        let minutes = Int(startTime) % 3600 / 60
        let seconds = Int(startTime) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    /// 获取关联的视频文件路径
    var associatedVideoPath: URL? {
        let srtURL = sourceFilePath
        let baseURL = srtURL.deletingPathExtension()
        
        // 常见的视频文件扩展名
        let videoExtensions = ["mp4", "mov", "mkv", "avi", "m4v", "wmv", "flv"]
        
        for ext in videoExtensions {
            let videoURL = baseURL.appendingPathExtension(ext)
            if FileManager.default.fileExists(atPath: videoURL.path) {
                return videoURL
            }
        }
        
        return nil
    }
    
    /// 获取源文件名（不含扩展名）
    var sourceFileName: String {
        sourceFilePath.deletingPathExtension().lastPathComponent
    }
}
