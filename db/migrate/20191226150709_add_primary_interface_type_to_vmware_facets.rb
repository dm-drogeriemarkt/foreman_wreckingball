# frozen_string_literal: true

class AddPrimaryInterfaceTypeToVmwareFacets < ActiveRecord::Migration[5.1]
  def change
    add_column :vmware_facets, :primary_interface_type, :string, index: true, null: true
  end
end
