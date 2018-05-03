# frozen_string_literal: true

module ForemanWreckingball
  module VmwareExtensions
    def hypervisors(opts = {})
      return [] unless opts[:cluster_id]
      cluster = cluster(opts[:cluster_id])
      name_sort(cluster.hosts.all)
    end
  end
end
