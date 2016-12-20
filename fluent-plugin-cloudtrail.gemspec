
Gem::Specification.new do |s|
  s.name   = 'fluent-plugin-cloudtrail'
  s.version = '0.0.1'
  s.date = '2016-12-19'
  s.summary = %q{Fluentd input plugin that inputs logs from AWS CloudTrail.}
  s.author = 'Craig Buchanan'
  s.email = 'craig+rubygems@blendlabs.com'
  s.files = [
    'LICENSE.txt',
    'lib/fluent/plugin/in_cloudtrail.rb'
  ]
  s.homepage = 'https://github.com/blendlabs/fluent-plugin-cloudtrail'
  s.license = 'MIT'

  s.add_dependency "fluentd", ">= 0.10.58", "< 2"
  s.add_dependency "aws-sdk", "~> 2"
end

