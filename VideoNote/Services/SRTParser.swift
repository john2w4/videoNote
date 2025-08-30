import Foundation

/// SRT字幕文件解析器
class SRTParser: SubtitleParser {
    
    /// 支持的文件扩展名
    static var supportedExtensions: [String] {
        return ["srt"]
    }
    
    /// 检查是否支持该文件格式
    static func canParse(fileURL: URL) -> Bool {
        return supportedExtensions.contains(fileURL.pathExtension.lowercased())
    }
    
    /// 解析错误类型（保持向后兼容）
    enum ParseError: Error, LocalizedError {
        case fileNotFound
        case invalidFormat
        case encodingError
        
        var errorDescription: String? {
            switch self {
            case .fileNotFound:
                return "SRT文件未找到"
            case .invalidFormat:
                return "SRT文件格式无效"
            case .encodingError:
                return "文件编码错误"
            }
        }
    }
    
    /// 解析SRT文件
    /// - Parameter fileURL: SRT文件的URL
    /// - Returns: 解析后的字幕条目数组
    /// - Throws: 解析错误
    static func parse(fileURL: URL) throws -> [SubtitleEntry] {
        print("📄 开始解析SRT文件: \(fileURL.lastPathComponent)")
        
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
    
    /// 解析SRT内容字符串
    /// - Parameters:
    ///   - content: SRT文件内容
    ///   - sourceURL: 源文件URL
    /// - Returns: 解析后的字幕条目数组
    /// - Throws: 解析错误
    private static func parseContent(_ content: String, sourceURL: URL) throws -> [SubtitleEntry] {
        var entries: [SubtitleEntry] = []
        
        // 将内容按空行分割成块
        let block1 = content.components(separatedBy: "\r\n\r\n")
        let block2 = content.components(separatedBy: "\n\n")
        let block = block1.count > block2.count ? block1 : block2
        
        let blocks = block
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        for block in blocks {
            if let entry = try? parseBlock(block, sourceURL: sourceURL) {
                entries.append(entry)
            }
        }
        
        guard !entries.isEmpty else {
            throw SubtitleParseError.invalidFormat
        }
        
        print("✅ SRT解析完成，共解析 \(entries.count) 条字幕")
        return entries.sorted { $0.startTime < $1.startTime }
    }
    
    /// 解析单个SRT块
    /// - Parameters:
    ///   - block: SRT块内容
    ///   - sourceURL: 源文件URL
    /// - Returns: 字幕条目
    /// - Throws: 解析错误
    private static func parseBlock(_ block: String, sourceURL: URL) throws -> SubtitleEntry {
        let lines = block.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        guard lines.count >= 3 else {
            throw SubtitleParseError.invalidFormat
        }
        
        // 第一行：序号
        let trimmedString = lines[0].trimmingCharacters(in: .whitespacesAndNewlines)

        // 明确移除BOM字符 \u{FEFF}
        let cleanedString = trimmedString.replacingOccurrences(of: "\u{FEFF}", with: "")
        guard let sequenceNumber = Int(cleanedString) else {
            throw SubtitleParseError.invalidFormat
        }
        
        // 第二行：时间范围
        let timeString = lines[1]
        let (startTime, endTime) = try parseTimeRange(timeString)
        
        // 第三行及之后：字幕内容
        let content = lines[2...].joined(separator: "\n")
        
        return SubtitleEntry(
            startTime: startTime,
            endTime: endTime,
            content: content,
            sourceFilePath: sourceURL,
            sequenceNumber: sequenceNumber
        )
    }
    
    /// 解析时间范围字符串
    /// - Parameter timeString: 时间字符串 (例如: "00:01:30,500 --> 00:01:33,400")
    /// - Returns: 开始时间和结束时间的元组
    /// - Throws: 解析错误
    private static func parseTimeRange(_ timeString: String) throws -> (TimeInterval, TimeInterval) {
        let components = timeString.components(separatedBy: " --> ")
        guard components.count == 2 else {
            throw SubtitleParseError.invalidFormat
        }
        
        let startTime = try parseTimeInterval(components[0])
        let endTime = try parseTimeInterval(components[1])
        
        return (startTime, endTime)
    }
    
    /// 解析时间间隔
    /// - Parameter timeString: 时间字符串 (例如: "00:01:30,500")
    /// - Returns: 时间间隔（秒）
    /// - Throws: 解析错误
    private static func parseTimeInterval(_ timeString: String) throws -> TimeInterval {
        // 替换逗号为点号（处理毫秒分隔符）
        let normalizedTime = timeString.replacingOccurrences(of: ",", with: ".")
        
        // 解析格式: HH:MM:SS.mmm
        let components = normalizedTime.components(separatedBy: ":")
        guard components.count == 3 else {
            throw SubtitleParseError.invalidFormat
        }
        
        guard let hours = Double(components[0]),
              let minutes = Double(components[1]),
              let seconds = Double(components[2]) else {
            throw SubtitleParseError.invalidFormat
        }
        
        return hours * 3600 + minutes * 60 + seconds
    }
}
