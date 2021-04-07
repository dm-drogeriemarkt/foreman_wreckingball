# frozen_string_literal: true

module ForemanWreckingball
  class OperatingsystemStatus < ::ForemanWreckingball::Status
    NAME = N_('VM Operatingsystem').freeze
    DESCRIPTION = N_('The VM operatingsystem should match the operatingsystem installed.').freeze
    HOST_ASSOCIATION = :vmware_operatingsystem_status_object

    OK = 0
    MISMATCH = 1

    OK_STATUSES = [OK].freeze
    WARN_STATUSES = [MISMATCH].freeze
    ERROR_STATUSES = [].freeze

    LABELS = {
      OK => N_('OK'),
      MISMATCH => N_('VM OS is incorrect')
    }.freeze

    SEARCH_VALUES = {
      ok: OK,
      mismatch: MISMATCH
    }.freeze

    REMEDIATE_ACTION = ::Actions::ForemanWreckingball::Host::RemediateVmwareOperatingsystem
    DANGEROUS_REMEDIATE = true

    def to_status(_options = {})
      os_matches_identifier? ? OK : MISMATCH
    end

    def relevant?(_options = {})
      host&.vmware_facet
    end

    private

    def os_matches_identifier?
      guest_id = host.vmware_facet.guest_id
      vsphere_os = VsphereOsIdentifiers.lookup(guest_id)
      return true unless vsphere_os
      return true unless host.operatingsystem && host.architecture
      return false if vsphere_os.architecture && vsphere_os.architecture != host.architecture.name
      return false if vsphere_os.osfamily && vsphere_os.osfamily != host.operatingsystem.family
      return false if vsphere_os.name && vsphere_os.name != host.operatingsystem.name
      return false if vsphere_os.major && ![vsphere_os.major].flatten.include?(host.operatingsystem.major.to_i)
      return false if vsphere_os.release && ![vsphere_os.release].flatten.include?(host.facts['os::release::full'])
      true
    end
  end
end
