# frozen_string_literal: true

module ForemanWreckingball
  class SpectreV2Status < ::HostStatus::Status
    ENABLED = 0
    MISSING = 1

    def self.status_name
      N_('Spectre v2 Guest Mitigation Enabled')
    end

    def self.host_association
      :vmware_spectre_v2_status_object
    end

    def self.description
      N_('In order to use hardware based branch target injection mitigation within virtual machines, Hypervisor-Assisted Guest Mitigation must be enabled.')
    end

    def self.supports_remediate?
      true
    end

    def self.dangerous_remediate?
      true
    end

    def self.remediate_action
      ::Actions::ForemanWreckingball::Host::RemediateSpectreV2
    end

    def to_status(_options = {})
      guest_mitigation_enabled? ? ENABLED : MISSING
    end

    def to_global(_options = {})
      self.class.to_global(status)
    end

    def self.to_global(status)
      case status
      when MISSING
        HostStatus::Global::ERROR
      else
        HostStatus::Global::OK
      end
    end

    def self.global_ok_list
      [ENABLED]
    end

    def to_label(_options = {})
      case status
      when MISSING
        N_('Guest Mitigation Missing')
      else
        N_('Guest Mitigation Enabled')
      end
    end

    def relevant?(_options = {})
      host && host&.vmware_facet && host.vmware_facet.hardware_version.present? && host.vmware_facet.cpu_features.any?
    end

    def guest_mitigation_enabled?
      recent_hw_version? && required_cpu_features_present?
    end

    def recent_hw_version?
      host.vmware_facet.hardware_version.to_s.gsub(/^vmx-/, '').to_i >= 9
    end

    def required_cpu_features_present?
      !(host.vmware_facet.cpu_features.map(&:downcase) & ['cpuid.ibrs', 'cpuid.ibpb', 'cpuid.stibp']).empty?
    end
  end
end
