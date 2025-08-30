import Foundation
import RegexBuilder

/// ASS/SSA字幕文件解析器
class ASSParser: SubtitleParser {
    
    /// 支持的文件扩展名
    static var supportedExtensions: [String] {
        return ["ass", "ssa"]
    }
    
    /// 检查是否支持该文件格式
    static func canParse(fileURL: URL) -> Bool {
        return supportedExtensions.contains(fileURL.pathExtension.lowercased())
    }
    
    /// 解析ASS/SSA文件
    /// - Parameter fileURL: ASS文件的URL
    /// - Returns: 解析后的字幕条目数组
    /// - Throws: 解析错误
    static func parse(fileURL: URL) throws -> [SubtitleEntry] {
        print("📄 开始解析ASS文件: \(fileURL.lastPathComponent)")
        
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
    
    /// 解析ASS内容字符串
    /// - Parameters:
    ///   - content: ASS文件内容
    ///   - sourceURL: 源文件URL
    /// - Returns: 解析后的字幕条目数组
    /// - Throws: 解析错误
    private static func parseContent(_ content: String, sourceURL: URL) throws -> [SubtitleEntry] {
        var entries: [SubtitleEntry] = []
        var sequenceNumber = 1
        
        // 按行分割内容
        let lines = content.components(separatedBy: .newlines)
        var inEventsSection = false
        var formatFields: [String] = []
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // 检查是否进入Events部分
            if trimmedLine == "[Events]" {
                inEventsSection = true
                continue
            }
            
            // 检查是否离开Events部分
            if trimmedLine.hasPrefix("[") && trimmedLine != "[Events]" {
                inEventsSection = false
                continue
            }
            
            // 如果不在Events部分，跳过
            if !inEventsSection {
                continue
            }
            
            // 解析Format行
            if trimmedLine.hasPrefix("Format:") {
                let formatLine = String(trimmedLine.dropFirst(7)).trimmingCharacters(in: .whitespaces)
                formatFields = formatLine.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                continue
            }
            
            // 解析Dialogue行
            if trimmedLine.hasPrefix("Dialogue:") {
                if let entry = try? parseDialogueLine(trimmedLine, formatFields: formatFields, sourceURL: sourceURL, sequenceNumber: sequenceNumber) {
                    entries.append(entry)
                    sequenceNumber += 1
                }
            }
        }
        
        guard !entries.isEmpty else {
            throw SubtitleParseError.invalidFormat
        }
        
        print("✅ ASS解析完成，共解析 \(entries.count) 条字幕")
        return entries.sorted { $0.startTime < $1.startTime }
    }
    
    /// 解析单个Dialogue行
    /// - Parameters:
    ///   - line: Dialogue行内容
    ///   - formatFields: Format字段数组
    ///   - sourceURL: 源文件URL
    ///   - sequenceNumber: 序号
    /// - Returns: 字幕条目
    /// - Throws: 解析错误
    private static func parseDialogueLine(_ line: String, formatFields: [String], sourceURL: URL, sequenceNumber: Int) throws -> SubtitleEntry {
        // 移除"Dialogue:"前缀
        let dialogueLine = String(line.dropFirst(9)).trimmingCharacters(in: .whitespaces)
        
        // 按逗号分割，但要注意Text字段可能包含逗号
        let fields = parseDialogueFields(dialogueLine)
        
        guard fields.count >= formatFields.count else {
            throw SubtitleParseError.invalidFormat
        }
        
        // 查找Start、End和Text字段的索引
        guard let startIndex = formatFields.firstIndex(of: "Start"),
              let endIndex = formatFields.firstIndex(of: "End"),
              let textIndex = formatFields.firstIndex(of: "Text") else {
            throw SubtitleParseError.invalidFormat
        }
        
        // 解析时间
        let startTime = try parseASSTime(fields[startIndex])
        let endTime = try parseASSTime(fields[endIndex])
        
        // 获取文本内容并清理ASS标签
        let rawText = fields[textIndex]
        let cleanText = cleanASSText(rawText)
        
        return SubtitleEntry(
            startTime: startTime,
            endTime: endTime,
            content: cleanText,
            sourceFilePath: sourceURL,
            sequenceNumber: sequenceNumber
        )
    }
    
    /// 解析Dialogue字段，正确处理Text字段中的逗号
    /// - Parameter line: Dialogue行内容（已移除"Dialogue:"前缀）
    /// - Returns: 字段数组
    private static func parseDialogueFields(_ line: String) -> [String] {
        var fields: [String] = []
        var currentField = ""
        var inBraces = 0
        
        for char in line {
            if char == "{" {
                inBraces += 1
                currentField.append(char)
            } else if char == "}" {
                inBraces -= 1
                currentField.append(char)
            } else if char == "," && inBraces == 0 && fields.count < 9 {
                // 只有在不在大括号内且还没到Text字段时才分割
                fields.append(currentField.trimmingCharacters(in: .whitespaces))
                currentField = ""
            } else {
                currentField.append(char)
            }
        }
        
        // 添加最后一个字段
        fields.append(currentField.trimmingCharacters(in: .whitespaces))
        
        return fields
    }
    
    /// 解析ASS时间格式
    /// - Parameter timeString: 时间字符串 (例如: "0:00:14.20")
    /// - Returns: 时间间隔（秒）
    /// - Throws: 解析错误
    private static func parseASSTime(_ timeString: String) throws -> TimeInterval {
        // ASS时间格式: H:MM:SS.cc 或 H:MM:SS.ccc
        let components = timeString.components(separatedBy: ":")
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
    
    /// 清理ASS文本中的样式标签
    /// - Parameter text: 原始文本
    /// - Returns: 清理后的文本
    private static func cleanASSText(_ text: String) -> String {
        var cleanedText = text
        
        // 移除ASS样式标签 (例如: {\pos(435.8,46.9)}, {\r原文字幕}, \N等)
        cleanedText = cleanedText.replacingOccurrences(of: #"\{[^}]*\}"#, with: "", options: .regularExpression)
        
        // 替换ASS换行符
        cleanedText = cleanedText.replacingOccurrences(of: "\\N", with: "\n")
        cleanedText = cleanedText.replacingOccurrences(of: "\\n", with: "\n")
        
        // 移除其他ASS转义字符
        cleanedText = cleanedText.replacingOccurrences(of: "\\h", with: " ") // 硬空格
        
        // 清理多余的空白字符
        cleanedText = cleanedText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return cleanedText
    }
}
