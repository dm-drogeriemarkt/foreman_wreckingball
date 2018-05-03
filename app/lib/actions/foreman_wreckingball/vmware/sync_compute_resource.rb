# frozen_string_literal: true

module Actions
  module ForemanWreckingball
    module Vmware
      class SyncComputeResource < Actions::EntryAction
        middleware.use Actions::Middleware::KeepCurrentUser

        def plan(compute_resource)
          action_subject(compute_resource)
          plan_self
        end

        def run
          compute_resource = ComputeResource.find(input[:compute_resource][:id])
          ::ForemanWreckingball::VmwareClusterImporter.new(
            :compute_resource => compute_resource
          ).import!

          ::ForemanWreckingball::VmwareHypervisorImporter.new(
            :compute_resource => compute_resource.reload
          ).import!

          compute_resource.hosts.each(&:refresh_vmware_facet!)
        end

        def humanized_name
          _('Refresh Compute Resource')
        end

        def resource_locks
          :update
        end

        def rescue_strategy
          Dynflow::Action::Rescue::Skip
        end

        def self.cleanup_after
          '1d'
        end
      end
    end
  end
end
