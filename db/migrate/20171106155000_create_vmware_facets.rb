# frozen_string_literal: true

class CreateVmwareFacets < ActiveRecord::Migration[4.2]
  def change
    create_table :vmware_clusters do |t|
      t.string :name, limit: 255, index: true
      t.references :compute_resource, foreign_key: true

      t.timestamps null: false
    end

    create_table :vmware_hypervisor_facets do |t|
      t.references :host, null: false, foreign_key: true, index: true, unique: true
      t.references :vmware_cluster, foreign_key: true, index: true
      t.integer :cpu_cores
      t.integer :cpu_sockets
      t.integer :cpu_threads
      t.integer :memory, limit: 8
      t.string :uuid, limit: 255

      t.timestamps null: false
    end

    create_table :vmware_facets do |t|
      t.references :host, null: false, foreign_key: true, index: true, unique: true
      t.references :vmware_cluster, foreign_key: true, index: true
      t.integer :cpus
      t.integer :corespersocket
      t.integer :memory_mb
      t.string :guest_id, limit: 255, index: true
      t.integer :tools_state, default: 1, index: true
      t.boolean :cpu_hot_add, null: false, default: false

      t.timestamps null: false
    end
  end
end
