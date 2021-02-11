# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'user_editable_translations/version'

Gem::Specification.new do |spec|
  spec.name          = 'user_editable_translations'
  spec.version       = UserEditableTranslations::VERSION
  spec.authors       = ['Michael Sommer']
  spec.email         = ['michael.sommer@ogd.nl']
  spec.summary       = %q{Providing user-editable I18n translations}
  spec.description   = %q{Providing user-editable I18n translations}
  spec.homepage      = 'https://code.ogdsoftware.nl/pink-pwnies-digital-2000/user_editable_translations'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'i18n-active_record'
  spec.add_dependency 'activeadmin_addons'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'ci_reporter_rspec'
end
