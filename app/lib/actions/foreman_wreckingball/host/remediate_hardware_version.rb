# frozen_string_literal: true

module Actions
  module ForemanWreckingball
    module Host
      class RemediateHardwareVersion < Actions::EntryAction
        middleware.use Actions::Middleware::KeepCurrentUser

        def delay(delay_options, host)
          action_subject(host)
          super(delay_options, host)
        end

        def plan(host)
          action_subject(host)
          plan_self
        end

        # rubocop:todo Metrics/AbcSize, Metrics/MethodLength
        def run
          host = ::Host.find(input[:host][:id])

          output[:old_hardware_version] = host.vmware_facet.hardware_version

          initially_powered_on = host.power.ready?
          output[:initially_powered_on] = initially_powered_on

          vm = host.compute_object

          if initially_powered_on
            vm.stop
            vm.wait_for { power_state == 'poweredOff' }
            raise _('Could not shut down VM.') if vm.ready?
          end

          vm.vm_upgrade_hardware

          state = host.refresh_vmware_facet!
          output[:state] = state
          output[:new_hardware_version] = host.vmware_facet.hardware_version
        ensure
          vm.start if vm && initially_powered_on
        end
        # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

        def humanized_name
          _('Upgrade VM Hardware Version')
        end

        def humanized_input
          input[:host] && input[:host][:name]
        end

        def append_error(message)
          output[:errors] ||= []
          output[:errors] << message
        end

        def rescue_strategy
          Dynflow::Action::Rescue::Skip
        end
      end
    end
  end
end
