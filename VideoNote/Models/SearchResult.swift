import Foundation

/// 搜索结果数据模型
struct SearchResult: Identifiable, Hashable {
    let id: UUID
    let subtitleEntry: SubtitleEntry
    let matchedText: String        // 匹配的文本
    let highlightedContent: String // 高亮显示的内容
    let searchKeyword: String      // 原始搜索关键词
    let searchTerms: [String]      // 解析后的搜索词数组
    
    init(subtitleEntry: SubtitleEntry, searchKeyword: String) {
        self.id = UUID()
        self.subtitleEntry = subtitleEntry
        self.searchKeyword = searchKeyword
        self.matchedText = subtitleEntry.content
        
        // 解析搜索词
        self.searchTerms = SearchResult.parseSearchTerms(searchKeyword)
        
        // 创建高亮内容
        self.highlightedContent = SearchResult.createHighlightedContent(
            content: subtitleEntry.content,
            terms: self.searchTerms
        )
    }
    
    /// 解析搜索词，支持中英文逗号分隔
    private static func parseSearchTerms(_ query: String) -> [String] {
        let separators = CharacterSet(charactersIn: ",，")
        
        let terms = query
            .components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        // 如果没有找到分隔符，返回原查询词（去除首尾空格）
        if terms.count == 1 && terms.first == query.trimmingCharacters(in: .whitespacesAndNewlines) {
            return [query.trimmingCharacters(in: .whitespacesAndNewlines)]
        }
        
        return terms
    }
    
    /// 创建高亮显示的内容（支持多个关键词）
    private static func createHighlightedContent(content: String, terms: [String]) -> String {
        guard !terms.isEmpty else { return content }
        
        var result = content
        let options: NSString.CompareOptions = [.caseInsensitive, .diacriticInsensitive]
        
        // 为每个搜索词添加高亮标记
        for term in terms {
            guard !term.isEmpty else { continue }
            
            let mutableString = NSMutableString(string: result)
            let range = NSRange(location: 0, length: mutableString.length)
            
            // 查找所有匹配的位置（从后向前替换，避免位置偏移）
            var ranges: [NSRange] = []
            var searchRange = range
            
            while searchRange.location < mutableString.length {
                let foundRange = mutableString.range(of: term, options: options, range: searchRange)
                if foundRange.location == NSNotFound {
                    break
                }
                ranges.append(foundRange)
                searchRange.location = foundRange.location + foundRange.length
                searchRange.length = range.length - searchRange.location
            }
            
            // 从后向前替换，避免位置偏移
            for foundRange in ranges.reversed() {
                let originalText = mutableString.substring(with: foundRange)
                let highlightedText = "**\(originalText)**"
                mutableString.replaceCharacters(in: foundRange, with: highlightedText)
            }
            
            result = mutableString as String
        }
        
        return result
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
