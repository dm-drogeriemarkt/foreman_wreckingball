# frozen_string_literal: true

module ForemanWreckingball
  module ComputeResourceExtensions
    extend ActiveSupport::Concern
    include ForemanTasks::Concerns::ActionSubject

    included do
      has_many :vmware_clusters,
        class_name: 'ForemanWreckingball::VmwareCluster',
        inverse_of: :compute_resource, dependent: :destroy

      has_many :vmware_hypervisor_facets,
        class_name: '::ForemanWreckingball::VmwareHypervisorFacet',
        through: :vmware_clusters,
        inverse_of: :compute_resource

      has_many :hypervisor_hosts,
        class_name: 'Host::Managed',
        through: :vmware_hypervisor_facets,
        source: :host, inverse_of: :compute_resource
    end

    def action_input_key
      'compute_resource'
    end
  end
end
