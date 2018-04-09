module ForemanWreckingball
  class VmwareHypervisorFacet < ActiveRecord::Base
    include Facets::Base

    validates_lengths_from_database

    validates :host, :presence => true, :allow_blank => false

    belongs_to :vmware_cluster, :inverse_of => :vmware_hypervisor_facets, :class_name => 'ForemanWreckingball::VmwareCluster'

    has_many :vmware_facets, :class_name => '::ForemanWreckingball::VmwareFacet', :through => :vmware_clusters,
                             :inverse_of => :vmware_hypervisor_facets

    def self.sanitize_name(name)
      name.tr('_', '-').chomp('.').downcase
    end
  end
end
