import Foundation

/// 搜索结果数据模型
struct SearchResult: Identifiable, Hashable {
    let id: UUID
    let subtitleEntry: SubtitleEntry
    let matchedText: String        // 匹配的文本
    let highlightedContent: String // 高亮显示的内容
    let searchKeyword: String      // 搜索关键词
    
    init(subtitleEntry: SubtitleEntry, searchKeyword: String) {
        self.id = UUID()
        self.subtitleEntry = subtitleEntry
        self.searchKeyword = searchKeyword
        self.matchedText = subtitleEntry.content
        
        // 创建高亮内容
        self.highlightedContent = SearchResult.createHighlightedContent(
            content: subtitleEntry.content,
            keyword: searchKeyword
        )
    }
    
    /// 创建高亮显示的内容
    private static func createHighlightedContent(content: String, keyword: String) -> String {
        guard !keyword.isEmpty else { return content }
        
        // 使用不区分大小写的搜索
        let options: NSString.CompareOptions = [.caseInsensitive, .diacriticInsensitive]
        let range = NSRange(location: 0, length: content.count)
        
        let mutableString = NSMutableString(string: content)
        let searchRange = mutableString.range(of: keyword, options: options, range: range)
        
        if searchRange.location != NSNotFound {
            // 这里可以添加特殊标记用于后续在UI中高亮显示
            let highlightedKeyword = "**\(mutableString.substring(with: searchRange))**"
            mutableString.replaceCharacters(in: searchRange, with: highlightedKeyword)
        }
        
        return mutableString as String
    }
    
    /// 获取视频文件名
    var videoFileName: String {
        if let videoPath = subtitleEntry.associatedVideoPath {
            return videoPath.lastPathComponent
        }
        return subtitleEntry.sourceFileName + ".mp4" // 默认假设为mp4
    }
    
    /// 格式化的时间戳
    var formattedTime: String {
        subtitleEntry.formattedStartTime
    }
}
