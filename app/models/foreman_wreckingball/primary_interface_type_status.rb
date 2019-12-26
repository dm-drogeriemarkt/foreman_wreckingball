# frozen_string_literal: true

module ForemanWreckingball
  class PrimaryInterfaceTypeStatus < ::HostStatus::Status
    OK = 0
    WARNING = 1

    def self.status_name
      N_('VM Primary Interface Type')
    end

    def self.host_association
      :vmware_primary_interface_type_status_object
    end

    def self.description
      N_('In order to use full network speed, your VM should be configured with a paravirtualized network card driver such as VMXNET 3.')
    end

    def self.supports_remediate?
      false
    end

    #def self.dangerous_remediate?
    #  true
    #end

    #def self.remediate_action
    #  ::Actions::ForemanWreckingball::Host::RemediateHardwareVersion
    #end

    def to_status(_options = {})
      uses_e1000? ? WARNING : OK
    end

    def to_global(_options = {})
      self.class.to_global(status)
    end

    def self.to_global(status)
      case status
      when WARNING
        HostStatus::Global::WARN
      else
        HostStatus::Global::OK
      end
    end

    def self.global_ok_list
      [OK]
    end

    def to_label(_options = {})
      case status
      when WARNING
        N_('Using slow E1000 driver')
      else
        N_('OK')
      end
    end

    def relevant?(_options = {})
      host && host&.vmware_facet && host.vmware_facet.primary_interface_type.present?
    end

    def uses_e1000?
      host.vmware_facet.primary_interface_type == 'VirtualE1000'
    end
  end
end
