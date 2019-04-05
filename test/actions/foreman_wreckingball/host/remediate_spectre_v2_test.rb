# frozen_string_literal: true

require 'test_plugin_helper'

module Actions
  module ForemanWreckingball
    module Vmware
      class RemediateSpectreV2Test < ActiveSupport::TestCase
        include ::Dynflow::Testing
        setup do
          ::Fog.mock!
          # this is not stubbed correctly in fog-vsphere
          ::ForemanWreckingball.fog_vsphere_namespace::Server.any_instance.stubs(:cpuHotAddEnabled).returns(false)
          ::ForemanWreckingball.fog_vsphere_namespace::Server.any_instance.stubs(:hardware_version).returns('vmx-13')
          ::ForemanWreckingball::SpectreV2Status.any_instance.stubs(:recent_hw_version?).returns(true)
          ::PowerManager::Virt.any_instance.stubs(:ready?).returns(true)
          Setting::Wreckingball.load_defaults
        end
        teardown { ::Fog.unmock! }

        let(:compute_resource) do
          cr = FactoryBot.create(:compute_resource, :vmware, :with_taxonomy, :uuid => 'Solutions')
          ComputeResource.find(cr.id)
        end
        let(:uuid) { '5032c8a5-9c5e-ba7a-3804-832a03e16381' }
        let(:vm) { compute_resource.find_vm_by_uuid(uuid) }

        let(:host) do
          FactoryBot.create(
            :host,
            :managed,
            :with_vmware_facet,
            compute_resource: compute_resource,
            uuid: uuid
          )
        end

        let(:action_class) { ::Actions::ForemanWreckingball::Host::RemediateSpectreV2 }
        let(:action) do
          create_action(action_class).tap do |action|
            action.stubs(:action_subject).returns(host)
            action.input.update(
              host: {
                id: host.id
              }
            )
          end
        end
        let(:planned_action) do
          plan_action(action, host)
        end
        let(:runned_action) { run_action(planned_action) }

        test "it remediates the host's spectre v2 status" do
          assert_equal :success, runned_action.state
          assert_equal true, runned_action.output.fetch('state')
          assert_equal true, runned_action.output.fetch('initially_powered_on')
        end
      end
    end
  end
end
