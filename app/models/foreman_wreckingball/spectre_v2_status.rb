# frozen_string_literal: true

module ForemanWreckingball
  class SpectreV2Status < ::ForemanWreckingball::Status
    NAME = N_('Spectre v2 Guest Mitigation Enabled').freeze
    DESCRIPTION = N_('In order to use hardware based branch target injection mitigation within virtual machines, Hypervisor-Assisted Guest Mitigation must be enabled.').freeze
    HOST_ASSOCIATION = :vmware_spectre_v2_status_object

    ENABLED = 0
    MISSING = 1

    OK_STATUSES = [ENABLED].freeze
    WARN_STATUSES = [].freeze
    ERROR_STATUSES = [MISSING].freeze

    LABELS = {
      ENABLED => N_('Guest Mitigation Enabled'),
      MISSING => N_('Guest Mitigation Missing')
    }.freeze

    SEARCH_VALUES = {
      enabled: ENABLED,
      missing: MISSING
    }.freeze

    REMEDIATE_ACTION = ::Actions::ForemanWreckingball::Host::RemediateSpectreV2
    DANGEROUS_REMEDIATE = true

    def to_status(_options = {})
      guest_mitigation_enabled? ? ENABLED : MISSING
    end

    def relevant?(_options = {})
      host && host&.vmware_facet && host.vmware_facet.hardware_version.present? && host.vmware_facet.cpu_features.any?
    end

    private

    def guest_mitigation_enabled?
      recent_hw_version? && required_cpu_features_present?
    end

    def recent_hw_version?
      host.vmware_facet.hardware_version.to_s.gsub(/^vmx-/, '').to_i >= 9
    end

    def required_cpu_features_present?
      !(host.vmware_facet.cpu_features & ['cpuid.IBRS', 'cpuid.IBPB', 'cpuid.STIBP']).empty?
    end
  end
end
