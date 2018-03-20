module ForemanWreckingball
  module VmwareHypervisorFacetHostExtensions
    extend ActiveSupport::Concern

    included do
      has_one :vmware_hypervisor_facet, :class_name => '::ForemanWreckingball::VmwareHypervisorFacet', :foreign_key => :host_id, :inverse_of => :host, :dependent => :destroy
      has_one :vmware_cluster, :through => :vmware_hypervisor_facet

      #scoped_search :on => :last_report, :relation => :omaha_facet, :complete_value => true, :only_explicit => true, :rename => :last_omaha_report
      #scoped_search :on => :machineid, :relation => :omaha_facet, :rename => :omaha_machineid, :complete_value => true
    end
  end
end
