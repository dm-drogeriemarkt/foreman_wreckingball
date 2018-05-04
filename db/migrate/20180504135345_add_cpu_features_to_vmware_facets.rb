# frozen_string_literal: true

class AddCpuFeaturesToVmwareFacets < ActiveRecord::Migration[5.1]
  def change
    add_column :vmware_facets, :cpu_features, :text
  end
end
