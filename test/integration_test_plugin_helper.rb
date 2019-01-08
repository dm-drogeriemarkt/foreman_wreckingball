# frozen_string_literal: true

require 'integration_test_helper'

require 'webmock/minitest'
require 'webmock'

# Add plugin to FactoryBot's paths
FactoryBot.definition_file_paths << File.join(File.dirname(__FILE__), 'factories')
FactoryBot.reload

WebMock.disable_net_connect!(allow_localhost: true)
