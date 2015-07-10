Pod::Spec.new do |s|
  s.name             = "MXSqlite"
  s.version          = "0.1"
  s.summary          = "Save your object to sqlite easily"

  s.homepage         = "https://github.com/antiguab/BAFluidView"

  s.license          = 'MIT'
  s.author           = { "Eric Lung" => "longminxiang@163@gmail.com" }
  s.source           = { :git => "https://github.com/longminxiang/MXSQL.git", :tag => s.version.to_s }
  s.platform     = :ios, '6.0'
  s.requires_arc = true

  s.source_files = 'MXSqlite/*'

end