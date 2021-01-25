# frozen_string_literal: true

module ForemanWreckingball
  class VmwareHypervisorFacet < ApplicationRecord
    include Facets::Base

    validates_lengths_from_database

    validates :host, presence: true, allow_blank: false

    belongs_to :vmware_cluster, inverse_of: :vmware_hypervisor_facets, class_name: '::ForemanWreckingball::VmwareCluster'
    has_one :compute_resource, inverse_of: :vmware_hypervisor_facets, through: :vmware_cluster
    has_many :vmware_facets, inverse_of: :vmware_hypervisor_facets, through: :vmware_cluster

    serialize :feature_capabilities, JSON

    def self.sanitize_name(name)
      name.tr('_', '-').chomp('.').downcase
    end

    def provides_spectre_features?
      !((feature_capabilities || []) & ['cpuid.IBRS', 'cpuid.IBPB', 'cpuid.STIBP']).empty?
    end
  end
end
