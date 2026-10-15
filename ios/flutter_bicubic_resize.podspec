Pod::Spec.new do |s|
  s.name             = 'flutter_bicubic_resize'
  s.version          = '1.9.1'
  s.summary          = 'Bicubic image resize for Flutter using native C code'
  s.description      = 'Cross-platform bicubic image resizing with identical results on iOS and Android'
  s.homepage         = 'https://github.com/erykkruk/BICUBIC_FLUTTER'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'Eryk Kruk' => 'eryk@codigee.com' }
  s.source           = { :path => '.' }
  # SPM-compatible layout (also consumed by Swift Package Manager via Package.swift)
  s.source_files     = 'flutter_bicubic_resize/Sources/flutter_bicubic_resize/**/*.{h,m,c}'
  s.public_header_files = 'flutter_bicubic_resize/Sources/flutter_bicubic_resize/include/**/*.h'
  s.module_map       = 'flutter_bicubic_resize/Sources/flutter_bicubic_resize/include/cocoapods_flutter_bicubic_resize.modulemap'
  s.platform         = :ios, '13.0'
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
