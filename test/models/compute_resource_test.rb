# frozen_string_literal: true

require 'test_plugin_helper'

class ComputeResourceTest < ActiveSupport::TestCase
  should have_many(:vmware_clusters)
  should have_many(:vmware_hypervisor_facets)
  should have_many(:hypervisor_hosts)
end
