import SwiftUI
import AppKit

/// 简化的中文友好文本编辑器
struct SimplifiedTextEditor: NSViewRepresentable {
    @Binding var text: String
    let onTextChange: (String) -> Void
    let onCursorPositionChange: (Int) -> Void
    
    init(text: Binding<String>, 
         onTextChange: @escaping (String) -> Void = { _ in }, 
         onCursorPositionChange: @escaping (Int) -> Void = { _ in }) {
        self._text = text
        self.onTextChange = onTextChange
        self.onCursorPositionChange = onCursorPositionChange
    }
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView
        
        // 基本设置
        textView.delegate = context.coordinator
        textView.string = text
        textView.font = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        textView.textColor = NSColor.labelColor
        textView.backgroundColor = NSColor.textBackgroundColor
        
        // 中文输入法支持 - 关键设置
        textView.isAutomaticTextReplacementEnabled = true  // 必须为 true
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        
        // 标记文本样式 - 用于显示拼音等临时文本
        textView.markedTextAttributes = [
            .backgroundColor: NSColor.selectedTextBackgroundColor.withAlphaComponent(0.2),
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        
        // 禁用其他自动功能，但保持文本替换
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isAutomaticDataDetectionEnabled = false
        textView.isAutomaticLinkDetectionEnabled = false
        
        // 布局设置
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(width: scrollView.frame.width, height: CGFloat.greatestFiniteMagnitude)
        
        context.coordinator.textView = textView
        
        return scrollView
    }
    
    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        let textView = scrollView.documentView as! NSTextView
        
        // 重要：不在输入法激活时更新文本
        guard !textView.hasMarkedText() else {
            return
        }
        
        if textView.string != text {
            let selectedRange = textView.selectedRange()
            textView.string = text
            // 保持光标位置
            if selectedRange.location <= text.count {
                textView.setSelectedRange(selectedRange)
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        let parent: SimplifiedTextEditor
        weak var textView: NSTextView?
        
        init(_ parent: SimplifiedTextEditor) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            
            DispatchQueue.main.async {
                self.parent.text = textView.string
                self.parent.onTextChange(textView.string)
                self.parent.onCursorPositionChange(textView.selectedRange().location)
            }
        }
        
        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            DispatchQueue.main.async {
                self.parent.onCursorPositionChange(textView.selectedRange().location)
            }
        }
        
        // 允许所有文本变化
        func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
            return true
        }
        
        // 让输入法正常处理所有命令
        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            return false
        }
    }
}
