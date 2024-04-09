# frozen_string_literal: true

case ENV['FOREMAN_VERSION']
when '3.7-stable', '3.8-stable'
  gem 'foreman-tasks', '~> 8.0'
end
