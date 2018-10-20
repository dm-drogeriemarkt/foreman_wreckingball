# frozen_string_literal: true

class AddPowerStateToVmwareFacets < ActiveRecord::Migration[5.1]
  def change
    add_column :vmware_facets, :power_state, :integer, default: 1, index: true
  end
end
