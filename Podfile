# Podfile for VideoNote with VLCKit integration

platform :osx, '13.0'

target 'VideoNote' do
  use_frameworks!
  
  # VLC媒体播放器框架 - 支持更多视频格式
  pod 'VLCKit', :git => 'https://github.com/videolan/vlckit.git', :branch => 'master'
  
  # 如果需要使用本地版本或特定版本
  # pod 'VLCKit', '~> 3.6.0'
  
end

# 后处理配置
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      # 设置最低部署目标
      config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '13.0'
      
      # VLCKit 特定配置
      if target.name == 'VLCKit'
        config.build_settings['ENABLE_BITCODE'] = 'NO'
        config.build_settings['VALID_ARCHS'] = 'x86_64 arm64'
      end
    end
  end
end
