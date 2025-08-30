import Foundation
import AppKit

/// Markdown导出器
class MarkdownExporter {
    
    /// 导出配置
    struct ExportConfiguration {
        let maxResults: Int
        let interval: Int
        let searchKeyword: String
        
        init(maxResults: Int = 100, interval: Int = 1, searchKeyword: String) {
            self.maxResults = maxResults
            self.interval = interval
            self.searchKeyword = searchKeyword
        }
    }
    
    /// 导出搜索结果为Markdown文件
    /// - Parameters:
    ///   - searchResults: 搜索结果数组
    ///   - configuration: 导出配置
    ///   - saveURL: 保存路径
    /// - Throws: 导出错误
    static func exportToMarkdown(
        searchResults: [SearchResult],
        configuration: ExportConfiguration,
        saveURL: URL
    ) throws {
        let markdownContent = generateMarkdownContent(
            searchResults: searchResults,
            configuration: configuration
        )
        
        try markdownContent.write(to: saveURL, atomically: true, encoding: .utf8)
    }
    
    /// 生成Markdown内容
    /// - Parameters:
    ///   - searchResults: 搜索结果
    ///   - configuration: 导出配置
    /// - Returns: Markdown字符串
    private static func generateMarkdownContent(
        searchResults: [SearchResult],
        configuration: ExportConfiguration
    ) -> String {
        var content = ""
        
        // 标题
        content += "# VidSearch 导出：搜索关键词 \"\(configuration.searchKeyword)\"\n\n"
        content += "导出时间: \(DateFormatter.exportFormatter.string(from: Date()))\n"
        content += "总结果数: \(searchResults.count)\n"
        content += "导出配置: 最大条数 \(configuration.maxResults), 间隔 \(configuration.interval)\n\n"
        content += "---\n\n"
        
        // 按视频文件分组
        let groupedResults = Dictionary(grouping: searchResults) { result in
            result.videoFileName
        }
        
        // 处理导出数量限制和间隔
        var exportedCount = 0
        var processedCount = 0
        
        for (videoFileName, results) in groupedResults.sorted(by: { $0.key < $1.key }) {
            // 检查是否达到最大导出数量
            if exportedCount >= configuration.maxResults {
                break
            }
            
            content += "## 来自于: \(videoFileName)\n\n"
            
            let sortedResults = results.sorted { $0.subtitleEntry.startTime < $1.subtitleEntry.startTime }
            
            for result in sortedResults {
                // 检查间隔设置
                if processedCount % configuration.interval == 0 {
                    if exportedCount >= configuration.maxResults {
                        break
                    }
                    
                    let cleanContent = result.subtitleEntry.content
                        .replacingOccurrences(of: "\n", with: " ")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    content += "- **[\(result.formattedTime)]** \(cleanContent)\n"
                    exportedCount += 1
                }
                processedCount += 1
            }
            
            content += "\n---\n\n"
        }
        
        content += "\n*由 VidSearch 自动生成*\n"
        
        return content
    }
    
    /// 显示保存对话框
    /// - Parameters:
    ///   - defaultName: 默认文件名
    ///   - completion: 完成回调
    @MainActor
    static func showSaveDialog(
        defaultName: String,
        completion: @escaping (URL?) -> Void
    ) {
        let savePanel = NSSavePanel()
        savePanel.title = "导出搜索结果"
        savePanel.message = "选择保存位置"
        savePanel.nameFieldStringValue = defaultName
        savePanel.allowedContentTypes = [.init(filenameExtension: "md")!]
        savePanel.canCreateDirectories = true
        
        savePanel.begin { response in
            if response == .OK {
                completion(savePanel.url)
            } else {
                completion(nil)
            }
        }
    }
}

// MARK: - DateFormatter Extension
extension DateFormatter {
    static let exportFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }()
}
