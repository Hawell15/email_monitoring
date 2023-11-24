# -*- encoding: utf-8 -*-
# stub: gmail 0.7.1 ruby lib

Gem::Specification.new do |s|
  s.name = "gmail".freeze
  s.version = "0.7.1".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Chris Kowalik".freeze]
  s.date = "2018-07-20"
  s.description = "A Rubyesque interface to Gmail, with all the tools you will need.\n  Search, read and send multipart emails; archive, mark as read/unread,\n  delete emails; and manage labels.\n  ".freeze
  s.email = ["chris@nu7hat.ch".freeze]
  s.homepage = "http://github.com/gmailgem/gmail".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.22".freeze
  s.summary = "A Rubyesque interface to Gmail, with all the tools you will need.".freeze

  s.installed_by_version = "3.4.22".freeze if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<gmail_xoauth>.freeze, [">= 0.3.0".freeze])
  s.add_runtime_dependency(%q<mail>.freeze, [">= 2.2.1".freeze])
  s.add_development_dependency(%q<gem-release>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, [">= 3.1".freeze])
  s.add_development_dependency(%q<rubocop>.freeze, [">= 0.34.2".freeze])
end
