# frozen_string_literal: true

module ForemanWreckingball
  class CpuHotAddStatus < ::ForemanWreckingball::Status
    NAME = N_('CPU Hot Plug').freeze
    DESCRIPTION = N_('Enabling CPU hot-add disables vNUMA, the virtual machine will instead use UMA. This might cause a performance degradation.').freeze
    HOST_ASSOCIATION = :vmware_cpu_hot_add_status_object

    OK = 0
    PERFORMANCE_DEGRADATION = 1

    OK_STATUSES = [OK].freeze
    WARN_STATUSES = [].freeze
    ERROR_STATUSES = [PERFORMANCE_DEGRADATION].freeze

    LABELS = {
      OK => N_('No Impact'),
      PERFORMANCE_DEGRADATION => N_('Possible performance degradation')
    }.freeze

    SEARCH_VALUES = {
      ok: OK,
      performance_degradation: PERFORMANCE_DEGRADATION
    }.freeze

    def to_status(_options = {})
      performance_degradation? ? PERFORMANCE_DEGRADATION : OK
    end

    def relevant?(_options = {})
      host&.vmware_facet && host.vmware_facet.try(:cpu_hot_add?)
    end

    private

    def performance_degradation?
      min_cores = hypervisor_min_cores
      return false unless min_cores
      host.vmware_facet.cpu_hot_add? && host.vmware_facet.cpus > min_cores
    end

    def hypervisor_min_cores
      host.vmware_facet.vmware_hypervisor_facets.minimum(:cpu_cores)
    end
  end
end
