# frozen_string_literal: true

class AddIndexesToVmwareHypervisorFacets < ActiveRecord::Migration[5.1]
  def change
    add_index :vmware_hypervisor_facets, :uuid
    add_index :vmware_hypervisor_facets, %i[vmware_cluster_id uuid]
  end
end
