module Actions
  module ForemanWreckingball
    module Host
      class RefreshVmwareFacet < Actions::EntryAction
        def plan(host)
          action_subject(host)
          plan_self
        end

        def run
          User.as_anonymous_admin do
            host = ::Host.find(input[:host][:id])
            state = host.refresh_vmware_facet!
            output[:state] = state
          end
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
