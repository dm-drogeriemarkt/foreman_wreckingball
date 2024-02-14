# frozen_string_literal: true

require Rails.root.join('config/environments/production.rb')

Foreman::Application.configure do
  config.assets.js_compressor = Uglifier.new(harmony: true) if defined?(Uglifier)
end
