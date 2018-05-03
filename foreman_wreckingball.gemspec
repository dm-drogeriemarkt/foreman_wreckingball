# frozen_string_literal: true

require File.expand_path('lib/foreman_wreckingball/version', __dir__)

Gem::Specification.new do |s|
  s.name        = 'foreman_wreckingball'
  s.version     = ForemanWreckingball::VERSION
  s.license     = 'GPL-3.0'
  s.authors     = ['Timo Goebel']
  s.email       = ['timo.goebel@dm.de']
  s.homepage    = 'https://github.com/dm-drogeriemarkt/foreman_wreckingball'
  s.summary     = 'Adds status checks of the VMWare VMs to Foreman.'
  # also update locale/gemspec.rb
  s.description = 'Adds status checks of the VMWare VMs to Foreman.'

  s.files = Dir['{app,config,db,lib,locale}/**/*'] + ['LICENSE', 'Rakefile', 'README.md']
  s.test_files = Dir['test/**/*']

  s.add_dependency 'foreman-tasks', '~> 0.11.2'
  s.add_development_dependency 'rdoc'
  s.add_development_dependency 'rubocop', '0.54.0'
end
