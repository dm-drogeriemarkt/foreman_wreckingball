# frozen_string_literal: true

module Actions
  module ForemanWreckingball
    module Host
      class RemediateVmwareOperatingsystem < Actions::EntryAction
        middleware.use Actions::Middleware::KeepCurrentUser

        def delay(delay_options, host)
          action_subject(host)
          super(delay_options, host)
        end

        def plan(host)
          action_subject(host)
          plan_self
        end

        def run
          host = ::Host.find(input[:host][:id])

          fail _('Foreman does not know the Architecture of this host.') unless host.architecture
          fail _('Foreman does not know the Operatingsystem of this host.') unless host.operatingsystem

          initially_powered_on = host.power.ready?
          output[:initially_powered_on] = initially_powered_on

          current_os_id = host.vmware_facet.guest_id
          current_os = VsphereOsIdentifiers.lookup(current_os_id)

          selectors = {
            :architecture => host.architecture.name,
            :osfamily => host.operatingsystem.family,
            :name => host.operatingsystem.name,
            :major => host.operatingsystem.major.to_i,
            :release => host.facts['os::release::full']
          }

          desired_os = VsphereOsIdentifiers.find_by(selectors)
          desired_os ||= VsphereOsIdentifiers.find_by(selectors.except(:major))
          desired_os ||= VsphereOsIdentifiers.find_by(selectors.except(:release))
          desired_os ||= VsphereOsIdentifiers.find_by(selectors.except(:major, :release))
          desired_os ||= VsphereOsIdentifiers.find_by(selectors.except(:major, :name))
          desired_os ||= VsphereOsIdentifiers.find_by(selectors.except(:major, :name, :release))

          fail _('Could not auto detect desired operatingsystem.') unless desired_os

          fail _('VMs current and desired OS (%s) already match. No update necessary.') % current_os.description if current_os == desired_os

          output[:old_operatingsystem] = current_os.description
          output[:old_operatingsystem_id] = current_os.id
          output[:new_operatingsytem] = desired_os.description
          output[:new_operatingsytem_id] = desired_os.id

          vm = host.compute_object

          if initially_powered_on
            vm.stop
            vm.wait_for { power_state == 'poweredOff' }
            fail _('Could not shut down VM.') if vm.ready?
          end

          vm.vm_reconfig_hardware('guestId' => desired_os.id)

          state = host.refresh_vmware_facet!
          output[:state] = state
        ensure
          vm.start if vm && initially_powered_on
        end

        def humanized_name
          _('Correct VM Operatingsystem')
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
