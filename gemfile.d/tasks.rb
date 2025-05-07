# frozen_string_literal: true

case ENV['FOREMAN_VERSION']
when '3.13-stable', '3.14-stable'
  gem 'foreman-tasks', '~> 10.0'
end
