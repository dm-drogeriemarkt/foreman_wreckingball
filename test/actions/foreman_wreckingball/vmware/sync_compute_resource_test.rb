# frozen_string_literal: true

require 'test_plugin_helper'

module Actions
  module ForemanWreckingball
    module Vmware
      class SyncComputeResourceTest < ActiveSupport::TestCase
        include ::Dynflow::Testing
        setup do
          ::Fog.mock!
          # Only Solutionscluster has valid mock data, let's ignore the rest
          ::Foreman::Model::Vmware.any_instance.stubs(:clusters).returns(['Solutionscluster'])
        end
        teardown { ::Fog.unmock! }

        let(:action_class) { ::Actions::ForemanWreckingball::Vmware::SyncComputeResource }
        let(:compute_resource) do
          FactoryBot.create(
            :vmware_cr,
            uuid: 'Solutions'
          )
        end

        let(:action) do
          create_action(action_class).tap do |action|
            action.stubs(:action_subject).returns(compute_resource)
            action.input.update(
              compute_resource: {
                id: compute_resource.id
              }
            )
          end
        end
        let(:planned_action) do
          plan_action(action, compute_resource)
        end
        let(:runned_action) { run_action(planned_action) }

        describe 'ComputeResource Sync' do
          test 'syncs a compute resource' do
            assert ::ForemanWreckingball::VmwareCluster.count.zero?
            assert_equal :success, runned_action.state
            refute ::ForemanWreckingball::VmwareCluster.count.zero?
          end
        end
      end
    end
  end
end
