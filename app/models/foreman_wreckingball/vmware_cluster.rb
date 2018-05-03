# frozen_string_literal: true

module ForemanWreckingball
  class VmwareCluster < ApplicationRecord
    has_many :vmware_hypervisor_facets,
             :class_name => '::ForemanWreckingball::VmwareHypervisorFacet',
             :inverse_of => :vmware_cluster,
             :dependent => :nullify
    has_many :hosts, :class_name => '::Host::Managed',
                     :through => :vmware_hypervisor_facets,
                     :inverse_of => :vmware_cluster,
                     :dependent => :nullify
    belongs_to :compute_resource,
               :inverse_of => :vmware_clusters
    has_many :vmware_facets,
             :class_name => '::ForemanWreckingball::VmwareFacet',
             :inverse_of => :vmware_cluster,
             :dependent => :nullify

    validates_lengths_from_database

    validates :compute_resource, :presence => true, :allow_blank => false
    validates :name, :presence => true, :allow_blank => false, :uniqueness => { scope: :compute_resource }
  end
end
