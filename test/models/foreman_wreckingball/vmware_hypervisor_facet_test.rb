# frozen_string_literal: true

require 'test_plugin_helper'

module ForemanWreckingball
  class VmwareHypervisorFacetTest < ActiveSupport::TestCase
    should validate_presence_of(:host)
    should belong_to(:vmware_cluster)
    should have_many(:vmware_facets)

    test 'should sanitize name' do
      assert_equal 'abc-server.example.com', ForemanWreckingball::VmwareHypervisorFacet.sanitize_name('abc_server.example.com.')
    end
  end
end
