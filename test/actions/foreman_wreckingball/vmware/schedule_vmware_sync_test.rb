# frozen_string_literal: true

require 'test_plugin_helper'

module Actions
  module ForemanWreckingball
    module Vmware
      class ScheduleVmwareSyncTest < ActiveSupport::TestCase
        include ::Dynflow::Testing

        let(:action_class) { ::Actions::ForemanWreckingball::Vmware::ScheduleVmwareSync }
        let(:sync_action_class) { ::Actions::ForemanWreckingball::Vmware::SyncComputeResource }

        let(:action) do
          create_action(action_class)
        end
        let(:planned_action) do
          plan_action(action)
        end

        context 'with a vmware compute resource' do
          test 'syncs a compute resource' do
            assert_action_planed_with(planned_action, sync_action_class, compute_resources(:vmware))
          end
        end
      end
    end
  end
end
