# frozen_string_literal: true

require 'test_plugin_helper'

module ForemanWreckingball
  class VmwareHypervisorFacetTest < ActiveSupport::TestCase
    should validate_presence_of(:host)
    should belong_to(:vmware_cluster)
    should have_many(:vmware_facets)
    should have_one(:compute_resource)

    test 'should sanitize name' do
      assert_equal 'abc-server.example.com', ForemanWreckingball::VmwareHypervisorFacet.sanitize_name('abc_server.example.com.')
    end

    describe '#provides_spectre_features?' do
      let(:facet) do
        FactoryBot.build(:vmware_hypervisor_facet)
      end

      test 'should be true when IBRS is available' do
        facet.feature_capabilities = ['cpuid.IBRS']
        assert facet.provides_spectre_features?
      end

      test 'should be true when IBPB is available' do
        facet.feature_capabilities = ['cpuid.IBPB']
        assert facet.provides_spectre_features?
      end

      test 'should be true when STIBP is available' do
        facet.feature_capabilities = ['cpuid.STIBP']
        assert facet.provides_spectre_features?
      end

      test 'should be false when neither IBRS, IBPB nor STIBP is available' do
        facet.feature_capabilities = ['cpuid.WHATEVER']
        assert_not facet.provides_spectre_features?
      end
    end
  end
end
