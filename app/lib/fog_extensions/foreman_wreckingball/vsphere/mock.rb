module FogExtensions
  module ForemanWreckingball
    module Vsphere
      module Mock
        extend ActiveSupport::Concern

        def vm_upgrade_hardware(version: nil, instance_uuid:)
          { 'task_state' => 'success' }
        end
      end
    end
  end
end
