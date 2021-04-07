# frozen_string_literal: true

module ForemanWreckingball
  class HardwareVersionStatus < ::ForemanWreckingball::Status
    NAME = N_('vSphere Hardware Version').freeze
    DESCRIPTION = N_('In order to use recent vSphere features, the VM must use a recent virtual hardware version.').freeze
    HOST_ASSOCIATION = :vmware_hardware_version_status_object

    OK = 0
    OUTOFDATE = 1

    OK_STATUSES = [OK].freeze
    WARN_STATUSES = [OUTOFDATE].freeze
    ERROR_STATUSES = [].freeze

    LABELS = {
      OK => N_('OK'),
      OUTOFDATE => N_('Out of date')
    }.freeze

    SEARCH_VALUES = {
      ok: OK,
      out_of_date: OUTOFDATE
    }.freeze

    REMEDIATE_ACTION = ::Actions::ForemanWreckingball::Host::RemediateHardwareVersion
    DANGEROUS_REMEDIATE = true

    def to_status(_options = {})
      recent_hw_version? ? OK : OUTOFDATE
    end

    def relevant?(_options = {})
      host && host&.vmware_facet && host.vmware_facet.hardware_version.present?
    end

    private

    def recent_hw_version?
      host.vmware_facet.hardware_version.to_s.gsub(/^vmx-/, '').to_i >= Setting[:min_vsphere_hardware_version]
    end
  end
end
