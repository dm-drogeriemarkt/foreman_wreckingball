# frozen_string_literal: true

module Actions
  module ForemanWreckingball
    module Vmware
      class ScheduleVmwareSync < Actions::EntryAction
        def plan
          compute_resources = ComputeResource.where(:type => 'Foreman::Model::Vmware')
          sequence do
            compute_resources.each do |compute_resource|
              plan_action(::Actions::ForemanWreckingball::Vmware::SyncComputeResource, compute_resource)
            end
          end
        end

        def humanized_name
          _('VMware Data Synchronization')
        end

        def rescue_strategy
          Dynflow::Action::Rescue::Skip
        end
      end
    end
  end
end
