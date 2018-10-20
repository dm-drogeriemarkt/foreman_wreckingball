# frozen_string_literal: true

require 'test_plugin_helper'

module ForemanWreckingball
  class VmwareFacetTest < ActiveSupport::TestCase
    should validate_presence_of(:host)
    should belong_to(:vmware_cluster)
    should have_many(:vmware_hypervisor_facets)

    describe '#refresh!' do
      let(:uuid) { '5032c8a5-9c5e-ba7a-3804-832a03e16381' }
      let(:vm) do
        OpenStruct.new(
          runtime: OpenStruct.new(
            featureRequirement: [
              'cpuid.SSE3',
              'cpuid.AES',
              'cpuid.Intel'
            ].map do |cpu_feature|
              OpenStruct.new(key: cpu_feature)
            end
          )
        )
      end

      let(:compute_resource) do
        cr = FactoryBot.create(:compute_resource, :vmware, :with_taxonomy, :uuid => 'Solutions')
        ComputeResource.find(cr.id)
      end

      let(:host) do
        FactoryBot.create(
          :host,
          :managed,
          :with_vmware_facet,
          compute_resource: compute_resource,
          uuid: uuid
        )
      end
      let(:vmware_facet) { host.vmware_facet }

      setup do
        ::Fog.mock!
        ::Fog::Compute::Vsphere::Mock.any_instance.stubs(:get_vm_ref).returns(vm)
        # this is not stubbed correctly in fog-vsphere
        ::Fog::Compute::Vsphere::Server.any_instance.stubs(:cpuHotAddEnabled).returns(false)
        ::Fog::Compute::Vsphere::Server.any_instance.stubs(:hardware_version).returns('vmx-9')
        ::Fog::Compute::Vsphere::Server.any_instance.stubs(:corespersocket).returns(1)
        ::Fog::Compute::Vsphere::Server.any_instance.stubs(:ready?).returns(true)
      end
      teardown { ::Fog.unmock! }

      test 'refreshes facet data from vm data' do
        vmware_facet.refresh!
        assert_equal 1, vmware_facet.cpus
        assert_equal 1, vmware_facet.corespersocket
        assert_equal 2196, vmware_facet.memory_mb
        assert_equal 'rhel6_64Guest', vmware_facet.guest_id
        assert_equal 'toolsOk', vmware_facet.tools_state
        assert_equal false, vmware_facet.cpu_hot_add
        assert_equal ['cpuid.SSE3', 'cpuid.AES', 'cpuid.Intel'], vmware_facet.cpu_features
        assert_equal 'vmx-9', vmware_facet.hardware_version
      end
    end
  end
end
