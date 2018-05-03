# frozen_string_literal: true

module ForemanWreckingball
  class ToolsStatus < ::HostStatus::Status
    POWERDOWN = 10

    def self.status_name
      N_('VMware Tools')
    end

    def self.host_association
      :vmware_tools_status_object
    end

    def self.description
      N_('VMWare Tools should be running and up-to-date.')
    end

    def self.supports_remediate?
      false
    end

    def to_status(_options = {})
      return POWERDOWN unless host.supports_power_and_running?
      VmwareFacet.tools_states[host.vmware_facet.tools_state]
    end

    def to_global(_options = {})
      case status
      when VmwareFacet.tools_states[:toolsOk], POWERDOWN
        HostStatus::Global::OK
      when VmwareFacet.tools_states[:toolsOld]
        HostStatus::Global::WARN
      else
        HostStatus::Global::ERROR
      end
    end

    def to_label(_options = {})
      return N_('Powered down') if status == POWERDOWN
      host.vmware_facet.tools_state_label
    end

    def relevant?(_options = {})
      host && !host.build? && host.vmware_facet
    end
  end
end
