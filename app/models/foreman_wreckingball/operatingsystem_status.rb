module ForemanWreckingball
  class OperatingsystemStatus < ::HostStatus::Status
    OK = 0
    MISMATCH = 1

    def self.status_name
      N_('VM Operatingsystem')
    end

    def self.host_association
      :vmware_operatingsystem_status_object
    end

    def self.description
      N_('The VM operatingsystem should match the operatingsystem installed.')
    end

    def self.supports_remediate?
      true
    end

    def self.remediate_action
      ::Actions::ForemanWreckingball::Host::RemediateVmwareOperatingsystem
    end

    def to_status(_options = {})
      os_matches_identifier? ? OK : MISMATCH
    end

    def to_global(_options = {})
      case status
      when MISMATCH
        HostStatus::Global::WARN
      else
        HostStatus::Global::OK
      end
    end

    def to_label(_options = {})
      case status
      when MISMATCH
        N_('VM OS is incorrect')
      else
        N_('OK')
      end
    end

    def relevant?(_options = {})
      host && !!host.vmware_facet
    end

    def os_matches_identifier?
      guest_id = host.vmware_facet.guest_id
      vsphere_os = VsphereOsIdentifiers.lookup(guest_id)
      return true unless vsphere_os
      os = host.operatingsystem
      return true unless host.operatingsystem && host.architecture
      return false if vsphere_os.architecture && vsphere_os.architecture != host.architecture.name
      return false if vsphere_os.osfamily && vsphere_os.osfamily != host.operatingsystem.family
      return false if vsphere_os.name && vsphere_os.name != host.operatingsystem.name
      return false if vsphere_os.major && vsphere_os.major != host.operatingsystem.major.to_i
      true
    end
  end
end
