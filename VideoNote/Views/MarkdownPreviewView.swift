import SwiftUI
@preconcurrency import WebKit

/// Markdown 预览视图
struct MarkdownPreviewView: NSViewRepresentable {
    let content: String
    let baseDirectory: URL?
    let onTimestampClick: (TimeInterval, String?) -> Void // 添加视频文件名参数
    
    // 便利初始化器，保持向后兼容性
    init(content: String, onTimestampClick: @escaping (TimeInterval, String?) -> Void) {
        self.content = content
        self.baseDirectory = nil
        self.onTimestampClick = onTimestampClick
    }
    
    // 完整初始化器
    init(content: String, baseDirectory: URL?, onTimestampClick: @escaping (TimeInterval, String?) -> Void) {
        self.content = content
        self.baseDirectory = baseDirectory
        self.onTimestampClick = onTimestampClick
    }
    
    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        
        // 启用本地文件访问
        configuration.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        configuration.setValue(true, forKey: "allowUniversalAccessFromFileURLs")
        
        // 启用开发者工具（调试模式）
        #if DEBUG
        configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")
        #endif
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        
        // 添加JavaScript消息处理器
        let userContentController = webView.configuration.userContentController
        userContentController.add(context.coordinator, name: "timestampClick")
        
        return webView
    }
    
    func updateNSView(_ webView: WKWebView, context: Context) {
        let newHTML = generateHTML(from: content)
        
        // 使用debouncing避免频繁更新
        context.coordinator.updateContentWithDebounce(webView, newHTML: newHTML)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // 将本地图片转换为base64编码
    private func convertLocalImagesToBase64(_ markdown: String) -> String {
        var html = markdown
        
        // 处理标准格式的图片: ![alt](src)
        let standardRegex = try? NSRegularExpression(pattern: #"!\[([^\]]*)\]\(([^)]+)\)"#, options: [])
        if let regex = standardRegex {
            let matches = regex.matches(in: html, options: [], range: NSRange(location: 0, length: html.count)).reversed()
            for match in matches {
                let altRange = Range(match.range(at: 1), in: html)!
                let srcRange = Range(match.range(at: 2), in: html)!
                let alt = String(html[altRange])
                let src = String(html[srcRange])
                
                print("🖼️ 处理图片: alt=\(alt), src=\(src)")
                
                // 检查是否是本地图片路径
                var imagePath: URL?
                
                if src.hasPrefix("/") {
                    // 绝对路径
                    imagePath = URL(fileURLWithPath: src)
                    print("📍 使用绝对路径: \(src)")
                } else if src.hasPrefix("images/") {
                    // 相对路径（兼容性处理）
                    if let baseDirectory = self.baseDirectory {
                        imagePath = baseDirectory.appendingPathComponent(src)
                        print("📍 使用相对路径: \(baseDirectory.path)/\(src)")
                    }
                } else if !src.hasPrefix("http") && !src.hasPrefix("data:") {
                    // 其他本地路径尝试
                    imagePath = URL(fileURLWithPath: src)
                    print("📍 尝试本地路径: \(src)")
                }
                
                if let imagePath = imagePath,
                   let base64String = imageToBase64(imagePath: imagePath) {
                    let replacement = "<img src=\"data:image/png;base64,\(base64String)\" alt=\"\(alt)\" />"
                    html = html.replacingCharacters(in: Range(match.range, in: html)!, with: replacement)
                    print("✅ 图片转换成功: \(imagePath.path)")
                } else {
                    print("❌ 图片转换失败: \(src)")
                }
            }
        }
        
        // 处理Obsidian格式的图片: ![[src|alt]]
        let obsidianRegex = try? NSRegularExpression(pattern: #"!\[\[([^|\]]+)(\|([^\]]*))?\]\]"#, options: [])
        if let regex = obsidianRegex {
            let matches = regex.matches(in: html, options: [], range: NSRange(location: 0, length: html.count)).reversed()
            for match in matches {
                let srcRange = Range(match.range(at: 1), in: html)!
                let src = String(html[srcRange])
                
                let alt: String
                if match.numberOfRanges > 3, let altRange = Range(match.range(at: 3), in: html) {
                    alt = String(html[altRange])
                } else {
                    alt = ""
                }
                
                print("🖼️ 处理Obsidian图片: alt=\(alt), src=\(src)")
                
                // 检查是否是本地图片路径
                var imagePath: URL?
                
                if src.hasPrefix("/") {
                    // 绝对路径
                    imagePath = URL(fileURLWithPath: src)
                } else if src.hasPrefix("images/") {
                    // 相对路径（兼容性处理）
                    if let baseDirectory = self.baseDirectory {
                        imagePath = baseDirectory.appendingPathComponent(src)
                    }
                } else if !src.hasPrefix("http") && !src.hasPrefix("data:") {
                    // 其他本地路径尝试
                    imagePath = URL(fileURLWithPath: src)
                }
                
                if let imagePath = imagePath,
                   let base64String = imageToBase64(imagePath: imagePath) {
                    let replacement = "<img src=\"data:image/png;base64,\(base64String)\" alt=\"\(alt)\" />"
                    html = html.replacingCharacters(in: Range(match.range, in: html)!, with: replacement)
                    print("✅ Obsidian图片转换成功: \(imagePath.path)")
                } else {
                    print("❌ Obsidian图片转换失败: \(src)")
                }
            }
        }
        
        return html
    }
    
    // 将图片文件转换为base64字符串
    private func imageToBase64(imagePath: URL) -> String? {
        do {
            let imageData = try Data(contentsOf: imagePath)
            return imageData.base64EncodedString()
        } catch {
            print("❌ 无法读取图片文件: \(imagePath.path) - \(error)")
            return nil
        }
    }
    
    private func generateHTML(from markdown: String) -> String {
        // 简单的 Markdown 到 HTML 转换
        var html = markdown
        
        // 首先处理图片，将本地图片转换为base64编码
        html = convertLocalImagesToBase64(html)
        
        // ... 其余的markdown转换逻辑 ...
        
        // 先做基本的 Markdown 转换（但跳过链接处理）
        html = convertBasicMarkdownExceptLinks(html)
        
        // 处理新格式的时间戳链接: [timestamp](视频文件完整路径#timestamp)
        let newTimestampPattern = #"\[(\d{2}:\d{2}:\d{2})\]\(([^)#]+)#(\d{2}:\d{2}:\d{2})\)"#
        html = html.replacingOccurrences(
            of: newTimestampPattern,
            with: "<span class=\"timestamp\" data-timestamp=\"$1\" data-video=\"$2\" title=\"跳转到 $1\">$1</span>",
            options: .regularExpression
        )
        
        // 处理旧格式的兼容性 - 带视频文件名的链接
        let timestampWithVideoPattern = #"\[(\d{2}:\d{2}:\d{2})\]\(vidtime://(\d+(?:\.\d+)?)\?video=([^)]+)\)"#
        html = html.replacingOccurrences(
            of: timestampWithVideoPattern,
            with: "<span class=\"timestamp\" data-timestamp=\"$2\" data-video=\"$3\" title=\"跳转到 $1\">$1</span>",
            options: .regularExpression
        )
        
        // 处理旧格式的兼容性 - 仅时间戳的链接
        let timestampOnlyPattern = #"\[(\d{2}:\d{2}:\d{2})\]\(vidtime://(\d+(?:\.\d+)?)\)"#
        html = html.replacingOccurrences(
            of: timestampOnlyPattern,
            with: "<span class=\"timestamp\" data-timestamp=\"$2\" title=\"跳转到 $1\">$1</span>",
            options: .regularExpression
        )
        
        // 最后处理其他普通链接
        html = html.replacingOccurrences(of: #"\[([^\]]+)\]\(([^)]+)\)"#, with: "<a href=\"$2\">$1</a>", options: .regularExpression)
        
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                    line-height: 1.6;
                    color: #333;
                    max-width: 800px;
                    margin: 0 auto;
                    padding: 20px;
                }
                .timestamp {
                    background-color: #007AFF;
                    color: white;
                    padding: 4px 10px;
                    border-radius: 6px;
                    font-family: 'SF Mono', 'Monaco', monospace;
                    font-size: 0.9em;
                    font-weight: 600;
                    display: inline-block;
                    transition: all 0.2s ease;
                    border: 2px solid transparent;
                    cursor: pointer;
                    user-select: none;
                }
                .timestamp:hover {
                    background-color: #0056CC;
                    transform: translateY(-1px);
                    box-shadow: 0 2px 8px rgba(0, 122, 255, 0.3);
                    border-color: #0056CC;
                }
                .timestamp:active {
                    transform: translateY(0);
                    box-shadow: 0 1px 4px rgba(0, 122, 255, 0.2);
                }
                h1, h2, h3, h4, h5, h6 {
                    color: #2c3e50;
                    margin-top: 1.5em;
                    margin-bottom: 0.5em;
                }
                h2 {
                    border-bottom: 2px solid #f0f0f0;
                    padding-bottom: 0.3em;
                }
                h3 {
                    color: #34495e;
                }
                img {
                    max-width: 100%;
                    height: auto;
                    border-radius: 8px;
                    box-shadow: 0 2px 8px rgba(0,0,0,0.1);
                    margin: 1em 0;
                }
                pre {
                    background-color: #f8f9fa;
                    padding: 16px;
                    border-radius: 6px;
                    overflow-x: auto;
                }
                code {
                    background-color: #f8f9fa;
                    padding: 2px 4px;
                    border-radius: 3px;
                    font-family: 'SF Mono', 'Monaco', monospace;
                }
                blockquote {
                    border-left: 4px solid #007AFF;
                    padding-left: 16px;
                    margin-left: 0;
                    color: #666;
                    font-style: italic;
                    background-color: #f9f9f9;
                    padding: 0.5em 1em;
                    border-radius: 0 4px 4px 0;
                }
                hr {
                    border: none;
                    height: 1px;
                    background: linear-gradient(to right, #ddd, #aaa, #ddd);
                    margin: 2em 0;
                }
                em {
                    color: #666;
                    font-size: 0.9em;
                }
                ol, ul {
                    padding-left: 1.5em;
                }
                li {
                    margin-bottom: 0.5em;
                }
            </style>
                        <script>
                console.log('JavaScript loaded successfully');
                
                // 将时间戳字符串 (HH:MM:SS) 转换为秒数
                function timestampToSeconds(timestamp) {
                    try {
                        var parts = timestamp.split(':');
                        if (parts.length === 3) {
                            var hours = parseInt(parts[0], 10) || 0;
                            var minutes = parseInt(parts[1], 10) || 0;
                            var seconds = parseInt(parts[2], 10) || 0;
                            return hours * 3600 + minutes * 60 + seconds;
                        }
                        return parseFloat(timestamp) || 0; // 兼容旧格式的秒数
                    } catch (error) {
                        console.error('Error parsing timestamp:', timestamp, error);
                        return 0;
                    }
                }
                
                function handleTimestampClick(timestamp, video) {
                    try {
                        console.log('🎯 handleTimestampClick called with:', timestamp, video);
                        
                        // 转换时间戳为秒数
                        var timestampInSeconds = timestampToSeconds(timestamp);
                        console.log('⏱️ Converted timestamp to seconds:', timestampInSeconds);
                        
                        // 向Swift发送消息
                        var message = {
                            'timestamp': timestampInSeconds
                        };
                        
                        // 只有当video不为空且不是'undefined'字符串时才添加
                        if (video && video !== '' && video !== 'undefined') {
                            message['video'] = decodeURIComponent(video);
                            console.log('📹 Video path:', message['video']);
                        }
                        
                        console.log('📤 Sending message to Swift:', message);
                        
                        if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.timestampClick) {
                            window.webkit.messageHandlers.timestampClick.postMessage(message);
                            console.log('✅ Message sent successfully');
                        } else {
                            console.error('❌ Message handler not available');
                            console.log('window.webkit:', window.webkit);
                        }
                    } catch (error) {
                        console.error('❌ Error in handleTimestampClick:', error);
                    }
                }
                
                // 页面加载完成后设置事件监听器
                document.addEventListener('DOMContentLoaded', function() {
                    console.log('📄 DOM loaded, setting up event listeners');
                    
                    // 检查时间戳元素
                    var timestamps = document.querySelectorAll('.timestamp');
                    console.log('🔍 Found timestamp elements:', timestamps.length);
                    
                    // 为整个文档添加点击事件监听器
                    document.addEventListener('click', function(e) {
                        console.log('👆 Click detected on:', e.target.tagName, 'class:', e.target.className);
                        
                        if (e.target.classList.contains('timestamp')) {
                            console.log('🎯 Timestamp element clicked!');
                            e.preventDefault();
                            e.stopPropagation();
                            
                            // 从data属性获取值
                            var timestamp = e.target.getAttribute('data-timestamp');
                            var video = e.target.getAttribute('data-video');
                            
                            console.log('📊 Data attributes - timestamp:', timestamp, 'video:', video);
                            
                            if (timestamp) {
                                handleTimestampClick(timestamp, video || '');
                            } else {
                                console.error('❌ No timestamp data found');
                            }
                            
                            return false;
                        }
                    }, true); // 使用捕获阶段
                    
                    console.log('✅ Event listeners set up successfully');
                });
                
                // 页面完全加载后再次检查
                window.addEventListener('load', function() {
                    console.log('🌐 Window loaded, final check');
                    var timestamps = document.querySelectorAll('.timestamp');
                    console.log('🔍 Final timestamp count:', timestamps.length);
                    timestamps.forEach(function(el, i) {
                        console.log('Timestamp', i, ':', el.textContent, 'data-timestamp:', el.getAttribute('data-timestamp'));
                    });
                    
                    // 监听滚动事件用于调试
                    var scrollTimeout;
                    window.addEventListener('scroll', function() {
                        clearTimeout(scrollTimeout);
                        scrollTimeout = setTimeout(function() {
                            console.log('📍 当前滚动位置:', window.pageYOffset);
                        }, 100);
                    });
                });
            </script>
        </head>
        <body>
            \(html)
        </body>
        </html>
        """
    }
    
    private func convertBasicMarkdownExceptLinks(_ text: String) -> String {
        var html = text
        
        // 使用 NSRegularExpression 进行多行匹配
        do {
            // 标题
            let h3Regex = try NSRegularExpression(pattern: "^### (.+)$", options: [.anchorsMatchLines])
            html = h3Regex.stringByReplacingMatches(in: html, options: [], range: NSRange(location: 0, length: html.count), withTemplate: "<h3>$1</h3>")
            
            let h2Regex = try NSRegularExpression(pattern: "^## (.+)$", options: [.anchorsMatchLines])
            html = h2Regex.stringByReplacingMatches(in: html, options: [], range: NSRange(location: 0, length: html.count), withTemplate: "<h2>$1</h2>")
            
            let h1Regex = try NSRegularExpression(pattern: "^# (.+)$", options: [.anchorsMatchLines])
            html = h1Regex.stringByReplacingMatches(in: html, options: [], range: NSRange(location: 0, length: html.count), withTemplate: "<h1>$1</h1>")
            
            // 列表
            let unorderedListRegex = try NSRegularExpression(pattern: "^- (.+)$", options: [.anchorsMatchLines])
            html = unorderedListRegex.stringByReplacingMatches(in: html, options: [], range: NSRange(location: 0, length: html.count), withTemplate: "<li>$1</li>")
            
            let orderedListRegex = try NSRegularExpression(pattern: "^([0-9]+)\\. (.+)$", options: [.anchorsMatchLines])
            html = orderedListRegex.stringByReplacingMatches(in: html, options: [], range: NSRange(location: 0, length: html.count), withTemplate: "<li>$2</li>")
            
            // 水平线
            let hrRegex = try NSRegularExpression(pattern: "^---+$", options: [.anchorsMatchLines])
            html = hrRegex.stringByReplacingMatches(in: html, options: [], range: NSRange(location: 0, length: html.count), withTemplate: "<hr>")
        } catch {
            print("正则表达式错误: \(error)")
        }
        
        // 粗体和斜体
        html = html.replacingOccurrences(of: #"\*\*(.+?)\*\*"#, with: "<strong>$1</strong>", options: .regularExpression)
        html = html.replacingOccurrences(of: #"\*(.+?)\*"#, with: "<em>$1</em>", options: .regularExpression)
        
        // 代码块
        html = html.replacingOccurrences(of: #"```[\s\S]*?```"#, with: "<pre><code>$0</code></pre>", options: .regularExpression)
        html = html.replacingOccurrences(of: #"`(.+?)`"#, with: "<code>$1</code>", options: .regularExpression)
        
        // 图片已经在 convertLocalImagesToBase64 中处理了
        // 这里只处理剩余的图片（非本地图片）
        // 标准格式: ![alt](src)
        html = html.replacingOccurrences(of: #"!\[([^\]]*)\]\(([^)]+)\)"#, with: "<img src=\"$2\" alt=\"$1\" />", options: .regularExpression)
        // Obsidian格式: ![[src|alt]]
        html = html.replacingOccurrences(of: #"!\[\[([^|\]]+)(\|([^\]]*))?\]\]"#, with: "<img src=\"$1\" alt=\"$3\" />", options: .regularExpression)
        
        // 调试：打印生成的HTML中的图片标签
        let imageRegex = try? NSRegularExpression(pattern: "<img[^>]*>", options: [])
        if let regex = imageRegex {
            let matches = regex.matches(in: html, options: [], range: NSRange(location: 0, length: html.count))
            for match in matches {
                let imageTag = String(html[Range(match.range, in: html)!])
                print("🖼️ 生成的图片标签: \(imageTag)")
            }
        }
        
        // 包装列表项
        html = html.replacingOccurrences(of: #"(<li>.*</li>)"#, with: "<ul>$1</ul>", options: .regularExpression)
        
        // 处理连续的列表项
        html = html.replacingOccurrences(of: #"</ul>\s*<ul>"#, with: "", options: .regularExpression)
        
        // 检测并包装有序列表（基于内容模式判断）
        let orderedListPattern = #"(<li>\d+\.\s.*</li>)"#
        if html.range(of: orderedListPattern, options: .regularExpression) != nil {
            html = html.replacingOccurrences(of: #"<ul>(<li>\d+\..*?</li>(?:\s*<li>\d+\..*?</li>)*)</ul>"#, 
                                           with: "<ol>$1</ol>", 
                                           options: .regularExpression)
        }
        
        // 段落
        html = html.replacingOccurrences(of: "\n\n", with: "</p><p>")
        html = "<p>" + html + "</p>"
        
        // 清理空段落
        html = html.replacingOccurrences(of: "<p></p>", with: "")
        
        return html
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        let parent: MarkdownPreviewView
        var lastHTML: String = ""
        var savedScrollPosition: Double = 0
        var updateTimer: Timer?
        
        init(_ parent: MarkdownPreviewView) {
            self.parent = parent
        }
        
        func updateContentWithDebounce(_ webView: WKWebView, newHTML: String) {
            // 取消之前的定时器
            updateTimer?.invalidate()
            
            // 设置新的定时器，延迟更新以避免频繁刷新
            updateTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
                self.performUpdate(webView, newHTML: newHTML)
            }
        }
        
        private func performUpdate(_ webView: WKWebView, newHTML: String) {
            guard lastHTML != newHTML else { return }
            
            // 保存当前滚动位置
            webView.evaluateJavaScript("window.pageYOffset") { (result, error) in
                if let scrollY = result as? Double {
                    self.savedScrollPosition = scrollY
                }
                
                // 调试：打印baseURL和HTML内容
                if let baseURL = self.parent.baseDirectory {
                    print("🔗 MarkdownPreview baseURL: \(baseURL.path)")
                    print("📁 检查images目录是否存在: \(FileManager.default.fileExists(atPath: baseURL.appendingPathComponent("images").path))")
                } else {
                    print("⚠️ MarkdownPreview baseURL 为 nil")
                }
                
                // 加载新内容 - 使用更安全的方式加载本地文件
                if let baseURL = self.parent.baseDirectory {
                    // 使用loadHTMLString with baseURL来支持本地文件访问
                    webView.loadHTMLString(newHTML, baseURL: baseURL)
                } else {
                    // 如果没有baseURL，创建一个临时的data URL
                    webView.loadHTMLString(newHTML, baseURL: nil)
                }
                self.lastHTML = newHTML
            }
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "timestampClick",
               let messageBody = message.body as? [String: Any] {
                
                // 尝试多种方式解析timestamp
                var timestamp: TimeInterval = 0
                if let timestampDouble = messageBody["timestamp"] as? Double {
                    timestamp = timestampDouble
                } else if let timestampString = messageBody["timestamp"] as? String,
                          let timestampValue = TimeInterval(timestampString) {
                    timestamp = timestampValue
                } else {
                    print("❌ 无法解析timestamp: \(messageBody["timestamp"] ?? "nil")")
                    return
                }
                
                let videoFileName = messageBody["video"] as? String
                print("🎯 收到时间戳点击: timestamp=\(timestamp), video=\(videoFileName ?? "无")")
                parent.onTimestampClick(timestamp, videoFileName)
            }
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            // 阻止所有的vidtime://链接导航，因为我们用JavaScript处理
            if let url = navigationAction.request.url, url.scheme == "vidtime" {
                decisionHandler(.cancel)
                return
            }
            
            decisionHandler(.allow)
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // 页面加载完成后恢复滚动位置
            if savedScrollPosition > 0 {
                let script = "window.scrollTo(0, \(savedScrollPosition));"
                webView.evaluateJavaScript(script) { _, error in
                    if let error = error {
                        print("❌ 恢复滚动位置失败: \(error)")
                    } else {
                        print("✅ 已恢复滚动位置: \(self.savedScrollPosition)")
                    }
                    // 重置保存的滚动位置
                    self.savedScrollPosition = 0
                }
            }
        }
    }
}
