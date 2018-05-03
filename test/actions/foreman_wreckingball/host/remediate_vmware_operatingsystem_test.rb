# frozen_string_literal: true

require 'test_plugin_helper'

module Actions
  module ForemanWreckingball
    module Vmware
      class RemediateVmwareOperatingsystemTest < ActiveSupport::TestCase
        include ::Dynflow::Testing
        setup do
          ::Fog.mock!
          # this is not stubbed correctly in fog-vsphere
          Fog::Compute::Vsphere::Server.any_instance.stubs(:cpuHotAddEnabled).returns(false)
        end
        teardown { ::Fog.unmock! }

        let(:compute_resource) do
          cr = FactoryBot.create(:compute_resource, :vmware, :uuid => 'Solutions')
          ComputeResource.find(cr.id)
        end
        let(:uuid) { '5032c8a5-9c5e-ba7a-3804-832a03e16381' }
        let(:vm) { compute_resource.find_vm_by_uuid(uuid) }

        let(:operatingsystem) do
          FactoryBot.create(
            :operatingsystem,
            architectures: [architectures(:x86_64)],
            major: 6,
            minor: 1,
            type: 'Redhat',
            name: 'RedHat'
          )
        end

        let(:host) do
          FactoryBot.create(
            :host,
            :managed,
            :with_vmware_facet,
            architecture: architectures(:x86_64),
            operatingsystem: operatingsystem,
            compute_resource: compute_resource,
            uuid: uuid
          ).tap do |host|
            host.vmware_facet.update_attribute(:guest_id, 'asianux4_64Guest')
          end
        end

        let(:action_class) { ::Actions::ForemanWreckingball::Host::RemediateVmwareOperatingsystem }
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

        test "it remediates the host's vm operatingsystem" do
          assert_equal :success, runned_action.state
          assert_equal 'asianux4_64Guest', runned_action.output.fetch('old_operatingsystem_id')
          assert_equal 'rhel6_64Guest', runned_action.output.fetch('new_operatingsytem_id')
          assert_equal true, runned_action.output.fetch('state')
          assert_equal true, runned_action.output.fetch('initially_powered_on')
          assert_equal 'rhel6_64Guest', host.reload.vmware_facet.guest_id
        end
      end
    end
  end
end
