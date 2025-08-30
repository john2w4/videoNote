//
//  VideoNoteApp.swift
//  VideoNote
//
//  Created by wh on 2025/8/30.
//

import SwiftUI
import AppKit

/// 窗口委托类，处理窗口关闭事件
class WindowDelegate: NSObject, NSWindowDelegate {
    let searchViewModel: SearchViewModel
    
    init(searchViewModel: SearchViewModel) {
        self.searchViewModel = searchViewModel
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        // 检查是否有未保存的更改
        if searchViewModel.hasUnsavedChanges {
            let alert = NSAlert()
            alert.messageText = "确认退出"
            alert.informativeText = "您有未保存的笔记更改。是否要保存后退出？"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "保存并退出")
            alert.addButton(withTitle: "不保存退出")
            alert.addButton(withTitle: "取消")
            
            let response = alert.runModal()
            
            switch response {
            case .alertFirstButtonReturn: // 保存并退出
                searchViewModel.saveNoteContent()
                performCleanupAndExit()
                return false // 返回false，因为我们手动调用terminate
            case .alertSecondButtonReturn: // 不保存退出
                performCleanupAndExit()
                return false // 返回false，因为我们手动调用terminate
            default: // 取消
                return false
            }
        } else {
            // 没有未保存更改，显示简单确认对话框
            let alert = NSAlert()
            alert.messageText = "确认退出"
            alert.informativeText = "确定要退出 VideoNote 吗？"
            alert.alertStyle = .informational
            alert.addButton(withTitle: "退出")
            alert.addButton(withTitle: "取消")
            
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                performCleanupAndExit()
                return false // 返回false，因为我们手动调用terminate
            }
            return false
        }
    }
    
    private func performCleanupAndExit() {
        // 退出应用
        DispatchQueue.main.async {
            NSApplication.shared.terminate(nil)
        }
    }
}

@main
struct VideoNoteApp: App {
    @StateObject private var searchViewModel = SearchViewModel()
    @State private var windowDelegate: WindowDelegate?
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(searchViewModel)
                .onAppear {
                    setupWindowDelegate()
                }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
    }
    
    private func setupWindowDelegate() {
        DispatchQueue.main.async {
            if let window = NSApplication.shared.windows.first {
                let delegate = WindowDelegate(searchViewModel: searchViewModel)
                window.delegate = delegate
                self.windowDelegate = delegate
            }
        }
    }
}
