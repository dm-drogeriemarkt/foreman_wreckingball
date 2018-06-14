# frozen_string_literal: true

class AddFeatureCapabilitiesToVmwareHypervisorFacets < ActiveRecord::Migration[5.1]
  def change
    add_column :vmware_hypervisor_facets, :feature_capabilities, :text
  end
end
