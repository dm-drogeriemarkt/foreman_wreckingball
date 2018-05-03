# frozen_string_literal: true

module Actions
  module ForemanWreckingball
    module Host
      class RefreshVmwareFacet < Actions::EntryAction
        middleware.use Actions::Middleware::KeepCurrentUser

        def plan(host)
          action_subject(host)
          plan_self
        end

        def run
          host = ::Host.find(input[:host][:id])
          state = host.refresh_vmware_facet!
          output[:state] = state
        end

        def rescue_strategy
          Dynflow::Action::Rescue::Skip
        end

        def humanized_name
          _('Refresh VMware data')
        end

        def humanized_input
          input[:host] && input[:host][:name]
        end
      end
    end
  end
end
