import Foundation

/// 目录扫描器 - 负责扫描工作目录并构建字幕索引
@MainActor
class DirectoryScanner: ObservableObject {
    
    @Published var isScanning = false
    @Published var scanProgress: Double = 0.0
    @Published var scanStatus = "准备扫描"
    
    private let fileManager = FileManager.default
    
    /// 扫描指定目录下的所有字幕文件
    /// - Parameter directoryURL: 要扫描的目录URL
    /// - Returns: 所有字幕条目的数组
    func scanDirectory(_ directoryURL: URL) async throws -> [SubtitleEntry] {
        await MainActor.run {
            isScanning = true
            scanProgress = 0.0
            scanStatus = "正在扫描目录..."
        }
        
        defer {
            Task { @MainActor in
                isScanning = false
                scanProgress = 1.0
                scanStatus = "扫描完成"
            }
        }
        
        // 递归查找所有字幕文件（SRT, ASS, VTT）
        let subtitleFiles = try await findSubtitleFiles(in: directoryURL)
        
        await MainActor.run {
            scanStatus = "找到 \(subtitleFiles.count) 个字幕文件，开始解析..."
        }
        
        var allEntries: [SubtitleEntry] = []
        let totalFiles = subtitleFiles.count
        
        for (index, subtitleFile) in subtitleFiles.enumerated() {
            await MainActor.run {
                scanProgress = Double(index) / Double(totalFiles)
                scanStatus = "正在解析: \(subtitleFile.lastPathComponent)"
            }
            
            do {
                let entries = try SubtitleParserFactory.parse(fileURL: subtitleFile)
                allEntries.append(contentsOf: entries)
            } catch {
                print("解析字幕文件失败: \(subtitleFile.path), 错误: \(error)")
            }
        }
        
        await MainActor.run {
            scanProgress = 1.0
            scanStatus = "扫描完成，共解析 \(allEntries.count) 条字幕"
        }
        
        return allEntries
    }
    
    /// 递归查找目录下的所有字幕文件（SRT, ASS, VTT）
    /// - Parameter directoryURL: 目录URL
    /// - Returns: 字幕文件URL数组
    private func findSubtitleFiles(in directoryURL: URL) async throws -> [URL] {
        var subtitleFiles: [URL] = []
        
        let resourceKeys: [URLResourceKey] = [
            .isDirectoryKey,
            .isRegularFileKey
        ]
        
        guard let enumerator = fileManager.enumerator(
            at: directoryURL,
            includingPropertiesForKeys: resourceKeys,
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            throw NSError(domain: "DirectoryScanner", code: 1, userInfo: [NSLocalizedDescriptionKey: "无法创建目录枚举器"])
        }
        
        let supportedExtensions = ["srt", "ass", "ssa", "vtt", "webvtt"]
        
        for case let fileURL as URL in enumerator {
            let resourceValues = try fileURL.resourceValues(forKeys: Set(resourceKeys))
            
            if resourceValues.isRegularFile == true,
               supportedExtensions.contains(fileURL.pathExtension.lowercased()) {
                subtitleFiles.append(fileURL)
            }
        }
        
        return subtitleFiles
    }
    
    /// 验证目录是否可访问
    /// - Parameter directoryURL: 目录URL
    /// - Returns: 是否可访问
    func validateDirectory(_ directoryURL: URL) -> Bool {
        var isDirectory: ObjCBool = false
        let exists = fileManager.fileExists(atPath: directoryURL.path, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue && fileManager.isReadableFile(atPath: directoryURL.path)
    }
}
