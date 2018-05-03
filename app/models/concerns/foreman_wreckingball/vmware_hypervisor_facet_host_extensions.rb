# frozen_string_literal: true

module ForemanWreckingball
  module VmwareHypervisorFacetHostExtensions
    extend ActiveSupport::Concern

    included do
      has_one :vmware_hypervisor_facet, :class_name => '::ForemanWreckingball::VmwareHypervisorFacet', :foreign_key => :host_id, :inverse_of => :host, :dependent => :destroy
      has_one :vmware_cluster, :through => :vmware_hypervisor_facet
    end
  end
end
