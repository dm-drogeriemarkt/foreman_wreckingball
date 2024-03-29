# frozen_string_literal: true

require 'test_plugin_helper'

module Actions
  module ForemanWreckingball
    module Vmware
      class RefreshVmwareFacetTest < ActiveSupport::TestCase
        include ::Dynflow::Testing

        let(:uuid) { '5032c8a5-9c5e-ba7a-3804-832a03e16381' }
        let(:vm) { compute_resource.find_vm_by_uuid(uuid) }

        setup do
          ::Fog.mock!
          Fog::Vsphere::Compute::Mock.any_instance.stubs(:get_vm_ref).returns(vm)
          Fog::Vsphere::Compute::Server.any_instance.stubs(:ready?).returns(false)
          ::ForemanWreckingball::SpectreV2Status.any_instance.stubs(:recent_hw_version?).returns(true)
          # this is not stubbed correctly in fog-vsphere
          Fog::Vsphere::Compute::Server.any_instance.stubs(:cpuHotAddEnabled).returns(false)
        end
        teardown { ::Fog.unmock! }

        let(:compute_resource) do
          cr = FactoryBot.create(:compute_resource, :vmware, :with_taxonomy, uuid: 'Solutions')
          ComputeResource.find(cr.id)
        end

        let(:host) do
          FactoryBot.create(
            :host,
            :managed,
            :with_vmware_facet,
            compute_resource: compute_resource,
            uuid: uuid
          ).tap do |host|
            host.vmware_facet.update_attribute(:guest_id, 'asianux4_64Guest') # rubocop:disable Rails/SkipsModelValidations
          end
        end

        let(:action_class) { ::Actions::ForemanWreckingball::Host::RefreshVmwareFacet }
        let(:action) do
          create_action(action_class).tap do |action|
            action.stubs(:action_subject).returns(host)
            action.input.update(
              host: {
                id: host.id,
              }
            )
          end
        end
        let(:planned_action) do
          plan_action(action, host)
        end
        let(:runned_action) { run_action(planned_action) }

        test "it refreshes a host's vmware facet" do
          assert_equal :success, runned_action.state
          assert_equal 'rhel6_64Guest', host.reload.vmware_facet.guest_id
        end
      end
    end
  end
end
