import SwiftUI
import AppKit

/// 专门用于测试中文输入的简化文本编辑器
struct ChineseInputTestView: NSViewRepresentable {
    @Binding var text: String
    @State private var debugInfo: String = ""
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView
        
        // 最小化设置，专注于中文输入支持
        textView.delegate = context.coordinator
        textView.string = text
        textView.font = NSFont.systemFont(ofSize: 16)
        
        // 最重要的中文输入设置
        textView.isAutomaticTextReplacementEnabled = true
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        
        // 设置输入法标记文本的视觉样式
        textView.markedTextAttributes = [
            .backgroundColor: NSColor.selectedTextBackgroundColor.withAlphaComponent(0.3),
            .underlineStyle: NSUnderlineStyle.single.rawValue,
            .underlineColor: NSColor.systemBlue
        ]
        
        // 禁用可能干扰输入法的功能
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isAutomaticDataDetectionEnabled = false
        textView.isAutomaticLinkDetectionEnabled = false
        
        context.coordinator.textView = textView
        
        return scrollView
    }
    
    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        let textView = scrollView.documentView as! NSTextView
        
        // 关键：避免在输入法活动时更新文本
        if textView.hasMarkedText() {
            print("🔍 输入法活动中，跳过文本更新")
            return
        }
        
        if textView.string != text {
            let selectedRange = textView.selectedRange()
            textView.string = text
            textView.setSelectedRange(selectedRange)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        let parent: ChineseInputTestView
        weak var textView: NSTextView?
        
        init(_ parent: ChineseInputTestView) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            
            print("📝 文本变化: \(textView.string.prefix(50))...")
            print("🔍 是否有标记文本: \(textView.hasMarkedText())")
            if textView.hasMarkedText() {
                print("📍 标记文本: \(textView.markedRange())")
            }
            
            DispatchQueue.main.async {
                self.parent.text = textView.string
            }
        }
        
        // 输入法相关的重要代理方法
        func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
            if let replacement = replacementString {
                print("✏️ 文本将要改变: '\(replacement)' 在位置 \(affectedCharRange)")
            }
            return true
        }
        
        // 处理输入法命令
        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            print("⌨️ 命令: \(commandSelector)")
            return false // 让系统处理
        }
        
        // 输入法候选词选择
        func textView(_ textView: NSTextView, willChangeSelectionFromCharacterRange oldSelectedCharRange: NSRange, toCharacterRange newSelectedCharRange: NSRange) -> NSRange {
            print("🎯 选择变化: \(oldSelectedCharRange) -> \(newSelectedCharRange)")
            return newSelectedCharRange
        }
    }
}

/// 中文输入测试窗口
struct ChineseInputDebugView: View {
    @State private var testText = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("中文输入测试")
                .font(.title)
                .padding()
            
            Text("请在下面的文本框中尝试输入中文：")
                .font(.headline)
            
            ChineseInputTestView(text: $testText)
                .frame(height: 200)
                .border(Color.gray, width: 1)
                .padding()
            
            VStack(alignment: .leading, spacing: 10) {
                Text("测试说明：")
                    .font(.headline)
                
                Text("1. 切换到中文输入法（如拼音输入法）")
                Text("2. 尝试输入一些中文字符")
                Text("3. 观察是否能正常显示拼音和转换为汉字")
                Text("4. 检查控制台输出的调试信息")
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            Text("当前文本内容：\(testText)")
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            
            Spacer()
        }
        .padding()
    }
}
