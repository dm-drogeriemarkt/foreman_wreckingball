# frozen_string_literal: true

require 'test_plugin_helper'

class ComputeResourceTest < ActiveSupport::TestCase
  should have_many(:vmware_clusters)
end
