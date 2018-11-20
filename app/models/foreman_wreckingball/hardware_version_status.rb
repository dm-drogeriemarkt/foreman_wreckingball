# frozen_string_literal: true

module ForemanWreckingball
  class HardwareVersionStatus < ::HostStatus::Status
    OK = 0
    OUTOFDATE = 1

    def self.status_name
      N_('vSphere Hardware Version')
    end

    def self.host_association
      :vmware_hardware_version_status_object
    end

    def self.description
      N_('In order to use recent vSphere features, the VM must use a recent virtual hardware version.')
    end

    def self.supports_remediate?
      true
    end

    def self.dangerous_remediate?
      true
    end

    def self.remediate_action
      ::Actions::ForemanWreckingball::Host::RemediateHardwareVersion
    end

    def to_status(_options = {})
      recent_hw_version? ? OK : OUTOFDATE
    end

    def to_global(_options = {})
      self.class.to_global(status)
    end

    def self.to_global(status)
      case status
      when OUTOFDATE
        HostStatus::Global::WARN
      else
        HostStatus::Global::OK
      end
    end

    def self.global_ok_list()
      [OK]
    end

    def to_label(_options = {})
      case status
      when OUTOFDATE
        N_('Out of date')
      else
        N_('OK')
      end
    end

    def relevant?(_options = {})
      host && host&.vmware_facet && host.vmware_facet.hardware_version.present?
    end

    def recent_hw_version?
      host.vmware_facet.hardware_version.to_s.gsub(/^vmx-/, '').to_i >= Setting[:min_vsphere_hardware_version]
    end
  end
end
