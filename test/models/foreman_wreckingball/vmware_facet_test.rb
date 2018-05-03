# frozen_string_literal: true

require 'test_plugin_helper'

module ForemanWreckingball
  class VmwareFacetTest < ActiveSupport::TestCase
    should validate_presence_of(:host)
    should belong_to(:vmware_cluster)
    should have_many(:vmware_hypervisor_facets)
  end
end
