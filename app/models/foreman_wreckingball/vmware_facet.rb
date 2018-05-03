# frozen_string_literal: true

module ForemanWreckingball
  class VmwareFacet < ApplicationRecord
    include Facets::Base

    VALID_GUEST_STATUSES = [:toolsNotInstalled, :toolsNotRunning, :toolsOk, :toolsOld].freeze

    enum :tools_state => VALID_GUEST_STATUSES

    belongs_to :vmware_cluster, :class_name => '::ForemanWreckingball::VmwareCluster',
                                :inverse_of => :vmware_facets

    has_many :vmware_hypervisor_facets, :class_name => '::ForemanWreckingball::VmwareHypervisorFacet',
                                        :through => :vmware_cluster,
                                        :inverse_of => :vmware_facets

    validates_lengths_from_database

    validates :host, :presence => true, :allow_blank => false

    def tools_state_label
      case tools_state.to_sym
      when :toolsNotInstalled
        N_('Not installed')
      when :toolsNotRunning
        N_('Not running')
      when :toolsOk
        N_('OK')
      when :toolsOld
        N_('Out of date')
      end
    end

    def refresh!
      vm = host.compute_object
      return unless vm
      update(
        :vmware_cluster => ::ForemanWreckingball::VmwareCluster.find_by(:name => vm.cluster, :compute_resource => host.compute_resource),
        :cpus => vm.cpus,
        :corespersocket => vm.corespersocket,
        :memory_mb => vm.memory_mb,
        :tools_state => vm.tools_state,
        :guest_id => vm.guest_id,
        :cpu_hot_add => vm.cpuHotAddEnabled
      )
    end

    def refresh_statuses
      host.get_status(::ForemanWreckingball::ToolsStatus).refresh!
      host.get_status(::ForemanWreckingball::CpuHotAddStatus).refresh!
      host.get_status(::ForemanWreckingball::OperatingsystemStatus).refresh!
      host.refresh_global_status!
    end
  end
end
