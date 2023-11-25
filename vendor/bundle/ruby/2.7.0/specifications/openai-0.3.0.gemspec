# -*- encoding: utf-8 -*-
# stub: openai 0.3.0 ruby lib

Gem::Specification.new do |s|
  s.name = "openai".freeze
  s.version = "0.3.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "changelog_uri" => "https://github.com/nileshtrivedi/openai/blob/master/changelog.md", "homepage_uri" => "https://github.com/nileshtrivedi/openai", "source_code_uri" => "https://github.com/nileshtrivedi/openai" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Nilesh Trivedi".freeze, "Erik Berlin".freeze]
  s.bindir = "exe".freeze
  s.date = "2023-02-07"
  s.description = "OpenAI API client library to access GPT-3 in Ruby".freeze
  s.email = ["git@nileshtrivedi.com".freeze, "sferik@gmail.com".freeze]
  s.homepage = "https://github.com/nileshtrivedi/openai".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.3.0".freeze)
  s.rubygems_version = "3.4.22".freeze
  s.summary = "OpenAI API client library to access GPT-3 in Ruby".freeze

  s.installed_by_version = "3.4.22".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<bundler>.freeze, [">= 2".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 10".freeze])
  s.add_development_dependency(%q<rspec>.freeze, [">= 3.9".freeze])
  s.add_development_dependency(%q<webmock>.freeze, [">= 3.8".freeze])
end
