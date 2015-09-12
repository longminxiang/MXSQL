Pod::Spec.new do |s|
  s.name             = "MXSqlite"
  s.version          = "0.1.1"
  s.summary          = "Save your object to sqlite easily"

  s.homepage         = "https://github.com/longminxiang/MXSqlite"

  s.license          = 'MIT'
  s.author           = { "Eric Lung" => "longminxiang@gmail.com" }
  s.source           = { :git => "https://github.com/longminxiang/MXSqlite.git", :tag => "v" + s.version.to_s }
  s.dependency 'FMDB', '~> 2.5'
  s.platform     = :ios, '6.0'
  s.requires_arc = true

  s.source_files = 'MXSqlite/**/*.{h,m}'

end