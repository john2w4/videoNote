import SwiftUI
import AppKit

/// 自定义搜索文本输入框，防止回车后全选文本
struct CustomSearchTextField: NSViewRepresentable {
    @Binding var text: String
    let placeholder: String
    let isEnabled: Bool
    let onCommit: () -> Void
    
    init(text: Binding<String>, 
         placeholder: String = "", 
         isEnabled: Bool = true, 
         onCommit: @escaping () -> Void = {}) {
        self._text = text
        self.placeholder = placeholder
        self.isEnabled = isEnabled
        self.onCommit = onCommit
    }
    
    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()
        textField.delegate = context.coordinator
        textField.stringValue = text
        textField.placeholderString = placeholder
        textField.isEnabled = isEnabled
        textField.isBordered = true
        textField.bezelStyle = .roundedBezel
        textField.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        
        // 设置文本颜色
        textField.textColor = NSColor.labelColor
        textField.backgroundColor = NSColor.textBackgroundColor
        
        return textField
    }
    
    func updateNSView(_ textField: NSTextField, context: Context) {
        if textField.stringValue != text {
            textField.stringValue = text
        }
        textField.isEnabled = isEnabled
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextFieldDelegate {
        let parent: CustomSearchTextField
        
        init(_ parent: CustomSearchTextField) {
            self.parent = parent
        }
        
        func controlTextDidChange(_ obj: Notification) {
            guard let textField = obj.object as? NSTextField else { return }
            DispatchQueue.main.async {
                self.parent.text = textField.stringValue
            }
        }
        
        func controlTextDidEndEditing(_ obj: Notification) {
            guard let textField = obj.object as? NSTextField else { return }
            
            // 检查是否是按回车键结束编辑
            if let fieldEditor = textField.currentEditor() {
                // 获取当前光标位置
                let selectedRange = fieldEditor.selectedRange
                
                DispatchQueue.main.async {
                    self.parent.onCommit()
                    
                    // 恢复光标位置，防止全选
                    if let fieldEditor = textField.currentEditor() {
                        fieldEditor.selectedRange = NSRange(location: selectedRange.location, length: 0)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.parent.onCommit()
                }
            }
        }
    }
}

/// 为了与现有代码兼容，提供 textFieldStyle 方法
extension CustomSearchTextField {
    func textFieldStyle<S>(_ style: S) -> CustomSearchTextField where S : TextFieldStyle {
        // 对于自定义实现，忽略样式参数，因为我们已经在内部处理了样式
        return self
    }
    
    func disabled(_ disabled: Bool) -> CustomSearchTextField {
        return CustomSearchTextField(
            text: _text,
            placeholder: placeholder,
            isEnabled: !disabled,
            onCommit: onCommit
        )
    }
}
