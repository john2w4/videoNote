import Foundation

/// VTT (WebVTT) 字幕文件解析器
class VTTParser: SubtitleParser {
    
    /// 支持的文件扩展名
    static var supportedExtensions: [String] {
        return ["vtt", "webvtt"]
    }
    
    /// 检查是否支持该文件格式
    static func canParse(fileURL: URL) -> Bool {
        return supportedExtensions.contains(fileURL.pathExtension.lowercased())
    }
    
    /// 解析VTT文件
    /// - Parameter fileURL: VTT文件的URL
    /// - Returns: 解析后的字幕条目数组
    /// - Throws: 解析错误
    static func parse(fileURL: URL) throws -> [SubtitleEntry] {
        print("📄 开始解析VTT文件: \(fileURL.lastPathComponent)")
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw SubtitleParseError.fileNotFound
        }
        
        // 尝试不同的编码方式读取文件
        var content: String
        if let utf8Content = try? String(contentsOf: fileURL, encoding: .utf8) {
            content = utf8Content
        } else if let gbkData = try? Data(contentsOf: fileURL),
                  let gbkContent = String(data: gbkData, encoding: .init(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)))) {
            content = gbkContent
        } else if let latinContent = try? String(contentsOf: fileURL, encoding: .isoLatin1) {
            content = latinContent
        } else {
            throw SubtitleParseError.encodingError
        }
        
        return try parseContent(content, sourceURL: fileURL)
    }
    
    /// 解析VTT内容字符串
    /// - Parameters:
    ///   - content: VTT文件内容
    ///   - sourceURL: 源文件URL
    /// - Returns: 解析后的字幕条目数组
    /// - Throws: 解析错误
    private static func parseContent(_ content: String, sourceURL: URL) throws -> [SubtitleEntry] {
        var entries: [SubtitleEntry] = []
        var sequenceNumber = 1
        
        // 移除BOM和清理内容
        let cleanContent = content.replacingOccurrences(of: "\u{FEFF}", with: "")
        
        // 检查VTT文件头
        let lines = cleanContent.components(separatedBy: .newlines)
        guard !lines.isEmpty && lines[0].hasPrefix("WEBVTT") else {
            throw SubtitleParseError.invalidFormat
        }
        
        // 将内容按空行分割成块
        let blocks = cleanContent.components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && !$0.hasPrefix("WEBVTT") }
        
        for block in blocks {
            if let entry = try? parseVTTBlock(block, sourceURL: sourceURL, sequenceNumber: sequenceNumber) {
                entries.append(entry)
                sequenceNumber += 1
            }
        }
        
        guard !entries.isEmpty else {
            throw SubtitleParseError.invalidFormat
        }
        
        print("✅ VTT解析完成，共解析 \(entries.count) 条字幕")
        return entries.sorted { $0.startTime < $1.startTime }
    }
    
    /// 解析单个VTT块
    /// - Parameters:
    ///   - block: VTT块内容
    ///   - sourceURL: 源文件URL
    ///   - sequenceNumber: 序号
    /// - Returns: 字幕条目
    /// - Throws: 解析错误
    private static func parseVTTBlock(_ block: String, sourceURL: URL, sequenceNumber: Int) throws -> SubtitleEntry {
        let lines = block.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        guard lines.count >= 2 else {
            throw SubtitleParseError.invalidFormat
        }
        
        // 第一行可能是序号（可选），第二行是时间范围
        var timeLineIndex = 0
        var textStartIndex = 1
        
        // 如果第一行不包含"-->"，则第一行是序号
        if !lines[0].contains("-->") {
            timeLineIndex = 1
            textStartIndex = 2
            guard lines.count >= 3 else {
                throw SubtitleParseError.invalidFormat
            }
        }
        
        // 解析时间范围
        let timeString = lines[timeLineIndex]
        let (startTime, endTime) = try parseVTTTimeRange(timeString)
        
        // 获取字幕内容
        let content = lines[textStartIndex...].joined(separator: "\n")
        
        return SubtitleEntry(
            startTime: startTime,
            endTime: endTime,
            content: content,
            sourceFilePath: sourceURL,
            sequenceNumber: sequenceNumber
        )
    }
    
    /// 解析VTT时间范围字符串
    /// - Parameter timeString: 时间字符串 (例如: "00:01:30.500 --> 00:01:33.400")
    /// - Returns: 开始时间和结束时间的元组
    /// - Throws: 解析错误
    private static func parseVTTTimeRange(_ timeString: String) throws -> (TimeInterval, TimeInterval) {
        let components = timeString.components(separatedBy: " --> ")
        guard components.count == 2 else {
            throw SubtitleParseError.invalidFormat
        }
        
        let startTime = try parseVTTTime(components[0])
        let endTime = try parseVTTTime(components[1])
        
        return (startTime, endTime)
    }
    
    /// 解析VTT时间间隔
    /// - Parameter timeString: 时间字符串 (例如: "00:01:30.500")
    /// - Returns: 时间间隔（秒）
    /// - Throws: 解析错误
    private static func parseVTTTime(_ timeString: String) throws -> TimeInterval {
        // VTT时间格式: HH:MM:SS.mmm 或 MM:SS.mmm
        let normalizedTime = timeString.trimmingCharacters(in: .whitespaces)
        
        let components = normalizedTime.components(separatedBy: ":")
        
        var hours: Double = 0
        var minutes: Double = 0
        var seconds: Double = 0
        
        if components.count == 3 {
            // HH:MM:SS.mmm 格式
            guard let h = Double(components[0]),
                  let m = Double(components[1]),
                  let s = Double(components[2]) else {
                throw SubtitleParseError.invalidFormat
            }
            hours = h
            minutes = m
            seconds = s
        } else if components.count == 2 {
            // MM:SS.mmm 格式
            guard let m = Double(components[0]),
                  let s = Double(components[1]) else {
                throw SubtitleParseError.invalidFormat
            }
            minutes = m
            seconds = s
        } else {
            throw SubtitleParseError.invalidFormat
        }
        
        return hours * 3600 + minutes * 60 + seconds
    }
}
