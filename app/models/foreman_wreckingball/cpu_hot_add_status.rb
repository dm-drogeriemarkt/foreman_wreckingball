# frozen_string_literal: true

module ForemanWreckingball
  class CpuHotAddStatus < ::HostStatus::Status
    OK = 0
    PERFORMANCE_DEGRATION = 1

    def self.status_name
      N_('CPU Hot Plug')
    end

    def self.host_association
      :vmware_cpu_hot_add_status_object
    end

    def self.description
      N_('Enabling CPU hot-add disables vNUMA, the virtual machine will instead use UMA. This might cause a performance degration.') # rubocop:disable Layout/LineLength
    end

    def self.supports_remediate?
      false
    end

    def to_status(_options = {})
      performance_degration? ? PERFORMANCE_DEGRATION : OK
    end

    def to_global(_options = {})
      self.class.to_global(status)
    end

    def self.to_global(status)
      case status
      when PERFORMANCE_DEGRATION
        HostStatus::Global::ERROR
      else
        HostStatus::Global::OK
      end
    end

    def self.global_ok_list
      [OK]
    end

    def to_label(_options = {})
      case status
      when PERFORMANCE_DEGRATION
        N_('Possible performance degration')
      else
        N_('No Impact')
      end
    end

    def relevant?(_options = {})
      host&.vmware_facet && host.vmware_facet.try(:cpu_hot_add?)
    end

    def performance_degration?
      min_cores = hypervisor_min_cores
      return false unless min_cores
      host.vmware_facet.cpu_hot_add? && host.vmware_facet.cpus > min_cores
    end

    def hypervisor_min_cores
      host.vmware_facet.vmware_hypervisor_facets.minimum(:cpu_cores)
    end
  end
end
