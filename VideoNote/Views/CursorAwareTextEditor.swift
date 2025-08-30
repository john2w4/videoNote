import SwiftUI
import AppKit

/// 支持光标位置管理的自定义文本编辑器
struct CursorAwareTextEditor: NSViewRepresentable {
    @Binding var text: String
    let onTextChange: (String) -> Void
    let onCursorPositionChange: (Int) -> Void
    let onCoordinatorReady: (Coordinator) -> Void
    
    init(text: Binding<String>, 
         onTextChange: @escaping (String) -> Void, 
         onCursorPositionChange: @escaping (Int) -> Void,
         onCoordinatorReady: @escaping (Coordinator) -> Void = { _ in }) {
        self._text = text
        self.onTextChange = onTextChange
        self.onCursorPositionChange = onCursorPositionChange
        self.onCoordinatorReady = onCoordinatorReady
    }
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView
        
        textView.delegate = context.coordinator
        textView.string = text
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.font = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        textView.textColor = NSColor.labelColor
        textView.backgroundColor = NSColor.textBackgroundColor
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(width: scrollView.frame.width, height: CGFloat.greatestFiniteMagnitude)
        
        context.coordinator.textView = textView
        
        // 通知协调器已准备好
        DispatchQueue.main.async {
            onCoordinatorReady(context.coordinator)
        }
        
        return scrollView
    }
    
    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        let textView = scrollView.documentView as! NSTextView
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
        let parent: CursorAwareTextEditor
        weak var textView: NSTextView?
        
        init(_ parent: CursorAwareTextEditor) {
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
        
        /// 在光标位置插入文本
        func insertText(_ text: String) {
            guard let textView = textView else { return }
            
            let selectedRange = textView.selectedRange()
            textView.insertText(text, replacementRange: selectedRange)
            
            // 更新父级绑定
            DispatchQueue.main.async {
                self.parent.text = textView.string
                self.parent.onTextChange(textView.string)
                self.parent.onCursorPositionChange(textView.selectedRange().location)
            }
        }
    }
}
