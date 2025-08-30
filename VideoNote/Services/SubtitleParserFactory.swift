import Foundation

/// 字幕解析错误类型
enum SubtitleParseError: Error, LocalizedError {
    case fileNotFound
    case invalidFormat
    case encodingError
    case unsupportedFormat
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "字幕文件未找到"
        case .invalidFormat:
            return "字幕文件格式无效"
        case .encodingError:
            return "文件编码错误"
        case .unsupportedFormat:
            return "不支持的字幕格式"
        }
    }
}

/// 字幕解析器协议
protocol SubtitleParser {
    /// 支持的文件扩展名
    static var supportedExtensions: [String] { get }
    
    /// 解析字幕文件
    /// - Parameter fileURL: 字幕文件的URL
    /// - Returns: 解析后的字幕条目数组
    /// - Throws: 解析错误
    static func parse(fileURL: URL) throws -> [SubtitleEntry]
    
    /// 检查是否支持该文件格式
    /// - Parameter fileURL: 文件URL
    /// - Returns: 是否支持
    static func canParse(fileURL: URL) -> Bool
}

/// 字幕解析器工厂
class SubtitleParserFactory {
    /// 注册的解析器列表
    private static let parsers: [SubtitleParser.Type] = [
        SRTParser.self,
        ASSParser.self,
        VTTParser.self
    ]
    
    /// 获取适合指定文件的解析器
    /// - Parameter fileURL: 字幕文件URL
    /// - Returns: 适合的解析器类型，如果没有找到则返回nil
    static func getParser(for fileURL: URL) -> SubtitleParser.Type? {
        let fileExtension = fileURL.pathExtension.lowercased()
        
        for parserType in parsers {
            if parserType.supportedExtensions.contains(fileExtension) {
                return parserType
            }
        }
        
        return nil
    }
    
    /// 解析字幕文件
    /// - Parameter fileURL: 字幕文件URL
    /// - Returns: 解析后的字幕条目数组
    /// - Throws: 解析错误
    static func parse(fileURL: URL) throws -> [SubtitleEntry] {
        print("🎬 尝试解析字幕文件: \(fileURL.path)")
        print("📄 文件扩展名: \(fileURL.pathExtension)")
        
        guard let parserType = getParser(for: fileURL) else {
            print("❌ 不支持的字幕格式: \(fileURL.pathExtension)")
            throw SubtitleParseError.unsupportedFormat
        }
        
        print("✅ 找到适合的解析器: \(String(describing: parserType))")
        return try parserType.parse(fileURL: fileURL)
    }
}
