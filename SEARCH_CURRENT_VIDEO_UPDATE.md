# VideoNote - searchCurrentVideoSubtitles 多关键词搜索实现

## 更新时间
2025年8月31日

## 修改内容

### 原始实现
```swift
func searchCurrentVideoSubtitles(_ query: String) -> [SearchResult] {
    guard !query.isEmpty else { return [] }
    
    return currentSubtitles
        .filter { $0.content.localizedCaseInsensitiveContains(query) }
        .map { SearchResult(subtitleEntry: $0, searchKeyword: query) }
        .sorted { $0.subtitleEntry.startTime < $1.subtitleEntry.startTime }
}
```

### 新实现 ✅
```swift
func searchCurrentVideoSubtitles(_ query: String) -> [SearchResult] {
    guard !query.isEmpty else { return [] }
    
    // 先用,和，对输入字符串进行分割
    let searchTerms = parseSearchTerms(query)
    print("🔍 当前视频字幕搜索词解析: \(searchTerms)")
    
    // 使用分割之后的子串数组分别对字幕进行搜索，然后合并结果
    var allResults: [SearchResult] = []
    
    for term in searchTerms {
        let termResults = currentSubtitles
            .filter { $0.content.localizedCaseInsensitiveContains(term) }
            .map { SearchResult(subtitleEntry: $0, searchKeyword: query) }
        
        allResults.append(contentsOf: termResults)
    }
    
    // 去重（同一字幕条目可能被多个关键词匹配到）
    let uniqueResults = Dictionary(grouping: allResults) { $0.subtitleEntry.id }
        .compactMap { (_, results) in results.first }
    
    // 使用startTime排序
    return uniqueResults.sorted { $0.subtitleEntry.startTime < $1.subtitleEntry.startTime }
}
```

## 实现特点

### 1. 字符串分割
- **分隔符支持**：同时支持中文逗号（，）和英文逗号（,）
- **复用现有逻辑**：使用已有的 `parseSearchTerms(query)` 方法
- **边界处理**：自动处理空格和空字符串

### 2. 多关键词搜索
- **独立搜索**：每个关键词分别对字幕进行搜索
- **OR逻辑**：任意关键词匹配即可返回该字幕条目
- **结果合并**：将所有匹配结果合并到一个数组中

### 3. 去重处理
- **基于ID去重**：使用 `subtitleEntry.id` 进行去重
- **保持原始搜索词**：去重后仍保留原始的完整搜索查询字符串
- **高效算法**：使用 Dictionary grouping 进行高效去重

### 4. 排序
- **时间排序**：最终结果按 `startTime` 升序排列
- **一致性**：与其他搜索方法保持一致的排序规则

## 使用示例

### 输入示例
```
"学习,编程,技术"
"hello,world"
"教程，示例，代码"
```

### 处理过程
1. **分割**：`"学习,编程,技术"` → `["学习", "编程", "技术"]`
2. **搜索**：分别搜索包含"学习"、"编程"、"技术"的字幕
3. **合并**：合并所有匹配结果
4. **去重**：移除重复的字幕条目（同一条字幕可能包含多个关键词）
5. **排序**：按时间顺序排列

## 调试功能
- 添加了 `print("🔍 当前视频字幕搜索词解析: \(searchTerms)")` 来输出解析结果
- 便于调试和验证多关键词解析是否正确

## 兼容性
- **向后兼容**：单关键词搜索功能保持不变
- **性能优化**：通过 Dictionary grouping 实现高效去重
- **一致性**：与全局搜索 `performSearch` 方法保持逻辑一致

## 应用场景
这个方法主要用于：
1. 当前播放视频的字幕搜索
2. 实时字幕内容检索
3. 视频内容快速定位

与全局搜索 `performSearch` 不同，这个方法专注于当前视频的字幕内容，提供更精确的当前上下文搜索功能。
