# This calls the main test_helper in Foreman-core
require 'test_helper'
require 'dynflow/testing'

# Add plugin to FactoryBot's paths
FactoryGirl.definition_file_paths << File.join(File.dirname(__FILE__), 'factories')
FactoryGirl.reload
