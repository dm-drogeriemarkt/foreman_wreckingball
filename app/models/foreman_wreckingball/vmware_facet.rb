# frozen_string_literal: true

module ForemanWreckingball
  class VmwareFacet < ApplicationRecord
    include Facets::Base

    VALID_GUEST_STATUSES = [:toolsNotInstalled, :toolsNotRunning, :toolsOk, :toolsOld].freeze

    enum :tools_state => VALID_GUEST_STATUSES

    VALID_POWER_STATES = [:poweredOff, :poweredOn, :suspended].freeze
    enum :power_state => VALID_POWER_STATES

    belongs_to :vmware_cluster, :class_name => '::ForemanWreckingball::VmwareCluster',
                                :inverse_of => :vmware_facets

    has_many :vmware_hypervisor_facets, :class_name => '::ForemanWreckingball::VmwareHypervisorFacet',
                                        :through => :vmware_cluster,
                                        :inverse_of => :vmware_facets

    validates_lengths_from_database

    validates :host, :presence => true, :allow_blank => false

    serialize :cpu_features, JSON

    def refresh!
      vm = host.compute_object
      return unless vm
      data_for_update = {
        vmware_cluster: ::ForemanWreckingball::VmwareCluster.find_by(name: vm.cluster, compute_resource: host.compute_resource),
        cpus: vm.cpus,
        corespersocket: vm.corespersocket,
        memory_mb: vm.memory_mb,
        tools_state: vm.tools_state,
        power_state: vm.power_state,
        guest_id: vm.guest_id,
        cpu_hot_add: vm.cpuHotAddEnabled,
        hardware_version: vm.hardware_version,
        cpu_features: []
      }
      data_for_update[:cpu_features] = raw_vm_object.runtime.featureRequirement.map(&:key) if vm.ready?
      update(data_for_update)
    end

    def refresh_statuses
      ::HostStatus.wreckingball_statuses.each { |status| host.get_status(status).refresh! }
      host.refresh_global_status!
    end

    def vm_ready?
      power_state == 'poweredOn'
    end

    private

    def raw_vm_object
      instance_uuid = host.compute_object.try(:instance_uuid)
      return unless instance_uuid
      host.compute_resource.send(:client).send(:get_vm_ref, instance_uuid)
    end
  end
end
