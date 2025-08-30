# 测试新格式的 Markdown 图片渲染

## 格式说明

新的截图格式为：`![视频文件名 - timestamp](截图文件完整路径)[timestamp](视频文件完整路径#timestamp)`

其中：
- timestamp 格式为 `HH:MM:SS`（时:分:秒，无毫秒）
- 视频文件名为实际的文件名
- 截图文件完整路径为从根目录开始的完整路径
- 视频文件完整路径为从根目录开始的完整路径，后跟 `#timestamp`

## 测试样例

### 示例 1: 测试视频截图

![test_video.mp4 - 00:01:30](/Users/test/VideoNote/images/test_video_00_01_30_20250831_143022.png)[00:01:30](/Users/test/Videos/test_video.mp4#00:01:30)

### 示例 2: 真实路径测试

![sample.mkv - 00:05:15](/Volumes/big/Users/wh/Documents/VideoNote/screenshots/sample_00_05_15.png)[00:05:15](/Volumes/big/Users/wh/Documents/Videos/sample.mkv#00:05:15)

## 预期行为

- ✅ 图片应该正确显示（使用 base64 编码）
- ✅ 时间戳链接应该可以点击
- ✅ 点击链接时应该跳转到对应的视频时间
- ✅ 控制台应该显示图片处理的调试信息

## 调试说明

在浏览器控制台中应该能看到类似这样的日志：
```
🖼️ 处理图片: alt=test_video.mp4 - 00:01:30, src=/Users/test/VideoNote/images/test_video_00_01_30_20250831_143022.png
📍 使用绝对路径: /Users/test/VideoNote/images/test_video_00_01_30_20250831_143022.png
✅ 图片转换成功: /Users/test/VideoNote/images/test_video_00_01_30_20250831_143022.png
```
