# frozen_string_literal: true

module ForemanWreckingball
  class ToolsStatus < ::ForemanWreckingball::Status
    NAME = N_('VMware Tools').freeze
    DESCRIPTION = N_('VMWare Tools should be running and up-to-date.').freeze
    HOST_ASSOCIATION = :vmware_tools_status_object

    TOOLS_NOT_INSTALLED = VmwareFacet.tools_states[:toolsNotInstalled]
    TOOLS_NOT_RUNNING = VmwareFacet.tools_states[:toolsNotRunning]
    TOOLS_OK = VmwareFacet.tools_states[:toolsOk]
    TOOLS_OLD = VmwareFacet.tools_states[:toolsOld]
    POWERDOWN = 10

    OK_STATUSES = [TOOLS_OK, POWERDOWN].freeze
    WARN_STATUSES = [TOOLS_OLD].freeze
    ERROR_STATUSES = [TOOLS_NOT_INSTALLED, TOOLS_NOT_RUNNING].freeze

    LABELS = {
      TOOLS_NOT_INSTALLED => N_('Not installed'),
      TOOLS_NOT_RUNNING => N_('Not running'),
      TOOLS_OK => N_('OK'),
      TOOLS_OLD => N_('Out of date'),
      POWERDOWN => N_('Powered down')
    }.freeze

    SEARCH_VALUES = {
      tools_not_installed: TOOLS_NOT_INSTALLED,
      tools_not_running: TOOLS_NOT_RUNNING,
      tools_ok: TOOLS_OK,
      tools_old: TOOLS_OLD,
      powerdown: POWERDOWN
    }.freeze

    def to_status(_options = {})
      return POWERDOWN unless host.supports_power? && host.vmware_facet.vm_ready?

      VmwareFacet.tools_states[host.vmware_facet.tools_state]
    end

    def relevant?(_options = {})
      host && !host.build? && host.vmware_facet
    end
  end
end
