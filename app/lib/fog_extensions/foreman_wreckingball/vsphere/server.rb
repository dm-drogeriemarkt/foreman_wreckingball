module FogExtensions
  module ForemanWreckingball
    module Vsphere
      module Server
        extend ActiveSupport::Concern

        def vm_upgrade_hardware(version: nil)
          requires :instance_uuid
          service.vm_upgrade_hardware(instance_uuid: instance_uuid, version: version)
        end
      end
    end
  end
end
