# frozen_string_literal: true

require 'test_plugin_helper'

module ForemanWreckingball
  class VmwareClusterTest < ActiveSupport::TestCase
    should validate_presence_of(:compute_resource)
    should validate_presence_of(:name)
    should belong_to(:compute_resource)
    should have_many(:vmware_hypervisor_facets)
    should have_many(:hosts)
    should have_many(:vmware_facets)
  end
end
