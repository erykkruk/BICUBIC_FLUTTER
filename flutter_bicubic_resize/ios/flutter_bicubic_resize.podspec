Pod::Spec.new do |s|
  s.name             = 'flutter_bicubic_resize'
  s.version          = '1.0.0'
  s.summary          = 'Bicubic image resize for Flutter using native C code'
  s.description      = 'Cross-platform bicubic image resizing with identical results on iOS and Android'
  s.homepage         = 'https://github.com/YOUR_USERNAME/flutter_bicubic_resize'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'Your Name' => 'your.email@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = '../src/**/*.{h,c}'
  s.platform         = :ios, '11.0'
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'OTHER_CFLAGS' => '-fvisibility=default'
  }
end
