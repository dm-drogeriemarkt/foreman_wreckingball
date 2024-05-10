# frozen_string_literal: true

module ForemanWreckingball
  class VmwareClusterImporter
    attr_accessor :compute_resource, :counters

    def initialize(options = {})
      @compute_resource = options.fetch(:compute_resource)
      @counters = {}
    end

    def import!
      ActiveRecord::Base.transaction do
        delete_removed_clusters
        create_new_clusters
      end
      logger.info("Import clusters for '#{compute_resource}' completed. Added: #{counters[:added] || 0}, Updated: #{counters[:updated] || 0}, Deleted: #{counters[:deleted] || 0} clusters") # rubocop:disable Layout/LineLength
    end

    def delete_removed_clusters
      counters[:deleted] =
        ::ForemanWreckingball::VmwareCluster.where(compute_resource: compute_resource)
                                            .where.not(name: cluster_names)
                                            .destroy_all
    end

    def create_new_clusters
      existing_clusters = ::ForemanWreckingball::VmwareCluster.where(compute_resource: compute_resource).pluck(:name)
      clusters_to_create = cluster_names - existing_clusters
      clusters_to_create.each do |cluster_name|
        ::ForemanWreckingball::VmwareCluster.create(name: cluster_name, compute_resource: compute_resource)
      end
      counters[:added] = clusters_to_create.size
    end

    def cluster_names
      @cluster_names ||= compute_resource.clusters
    end

    private

    def logger
      ::Foreman::Logging.logger('foreman_wreckingball/import')
    end
  end
end
