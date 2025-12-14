Pod::Spec.new do |s|
  s.name             = 'flutter_bicubic_resize'
  s.version          = '1.2.0'
  s.summary          = 'Bicubic image resize for Flutter using native C code'
  s.description      = 'Cross-platform bicubic image resizing with identical results on iOS and Android'
  s.homepage         = 'https://github.com/erykkruk/BICUBIC_FLUTTER'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'Eryk Kruk' => 'eryk@codigee.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*.swift', 'src/**/*.{h,c}'
  s.public_header_files = 'src/**/*.h'
  s.platform         = :ios, '11.0'
  s.swift_version    = '5.0'
  s.static_framework = true
  # Build settings for the plugin target
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'OTHER_CFLAGS' => '-fvisibility=default',
    # Prevent symbol stripping in release builds
    'STRIP_STYLE' => 'non-global',
    'DEAD_CODE_STRIPPING' => 'NO',
    'STRIP_INSTALLED_PRODUCT' => 'NO'
  }

  # Propagate settings to the app target to prevent symbol stripping
  s.user_target_xcconfig = {
    'STRIP_STYLE' => 'non-global',
    'DEAD_CODE_STRIPPING' => 'NO'
  }

  s.dependency 'Flutter'
end
