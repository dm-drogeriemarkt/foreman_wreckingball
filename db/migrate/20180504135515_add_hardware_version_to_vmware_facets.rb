# frozen_string_literal: true

class AddHardwareVersionToVmwareFacets < ActiveRecord::Migration[5.1]
  def change
    add_column :vmware_facets, :hardware_version, :string
  end
end
