import SwiftUI

/// 导出配置视图
struct ExportConfigurationView: View {
    @ObservedObject var viewModel: SearchViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // 标题和说明
                headerSection
                
                Divider()
                
                // 配置选项
                configurationSection
                
                Divider()
                
                // 预览信息
                previewSection
                
                Spacer()
                
                // 操作按钮
                actionButtons
            }
            .padding(20)
            .frame(width: 400, height: 350)
            .navigationTitle("导出配置")
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "square.and.arrow.up")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                
                Text("导出搜索结果")
                    .font(.headline)
            }
            
            Text("将搜索结果导出为 Markdown 文件")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Configuration Section
    private var configurationSection: some View {
        VStack(spacing: 16) {
            // 最大导出条数
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("最大导出条数")
                        .font(.headline)
                    
                    Spacer()
                    
                    Text("\(viewModel.exportMaxResults)")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                Stepper("", value: $viewModel.exportMaxResults, in: 1...1000, step: 10)
                    .labelsHidden()
                
                Text("限制导出的最大结果数量")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // 结果间隔
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("结果间隔")
                        .font(.headline)
                    
                    Spacer()
                    
                    Text("\(viewModel.exportInterval)")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                Stepper("", value: $viewModel.exportInterval, in: 1...10, step: 1)
                    .labelsHidden()
                
                Text("每 \(viewModel.exportInterval) 条结果导出一个")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - Preview Section
    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("导出预览")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("搜索关键词:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\"\(viewModel.searchText)\"")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("总结果数:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(viewModel.searchResults.count)")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("实际导出数:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(actualExportCount)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.accentColor)
                }
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button("取消") {
                dismiss()
            }
            .buttonStyle(.bordered)
            
            Spacer()
            
            Button("导出") {
                viewModel.exportResults()
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.searchResults.isEmpty)
        }
    }
    
    // MARK: - Computed Properties
    private var actualExportCount: Int {
        let totalResults = viewModel.searchResults.count
        let maxResults = viewModel.exportMaxResults
        let interval = viewModel.exportInterval
        
        let intervalBasedCount = (totalResults + interval - 1) / interval
        return min(intervalBasedCount, maxResults)
    }
}

// MARK: - Preview
#Preview {
    ExportConfigurationView(viewModel: SearchViewModel())
}
