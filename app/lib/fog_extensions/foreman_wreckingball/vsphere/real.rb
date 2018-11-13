module FogExtensions
  module ForemanWreckingball
    module Vsphere
      module Real
        extend ActiveSupport::Concern

        module Overrides
          def host_system_attribute_mapping
            super.merge(
              feature_capabilities: 'config.featureCapability'
            )
          end

          def list_hosts(filters = {})
            super.map { |h| h[:feature_capabilities] = h[:feature_capabilities].map(&:key); h }
          end
        end

        included do
          prepend Overrides
        end

        def vm_upgrade_hardware(version: nil, instance_uuid:)
          vm_mob_ref = get_vm_ref(instance_uuid)
          task = vm_mob_ref.UpgradeVM_Task(version: version)
          task.wait_for_completion
          { 'task_state' => task.info.state }
        end
      end
    end
  end
end
