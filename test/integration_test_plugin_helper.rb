require 'integration_test_helper'

require 'webmock/minitest'
require 'webmock'
require 'pry'

# Add plugin to FactoryBot's paths
FactoryBot.definition_file_paths << File.join(File.dirname(__FILE__), 'factories')
FactoryBot.reload
