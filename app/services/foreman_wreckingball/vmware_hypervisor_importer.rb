# frozen_string_literal: true

module ForemanWreckingball
  class VmwareHypervisorImporter
    attr_accessor :compute_resource, :counters

    def initialize(options = {})
      @compute_resource = options.fetch(:compute_resource)
      @hypervisors = {}
      @counters = {}
    end

    def import!
      compute_resource.refresh_cache
      compute_resource.vmware_clusters.each do |cluster|
        import_hypervisors(cluster)
        delete_removed_hypervisors(cluster)
      end
      logger.info("Import hypervisors for '#{compute_resource}' completed. Added: #{counters[:added] || 0}, Updated: #{counters[:updated] || 0}, Deleted: #{counters[:deleted] || 0} hypervisors") # rubocop:disable Layout/LineLength
    end

    def import_hypervisors(cluster)
      hypervisors(cluster).each do |hypervisor|
        import_hypervisor(cluster, hypervisor)
      end
    end

    # rubocop:todo Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    def import_hypervisor(cluster, hypervisor)
      host = find_host_for_hypervisor(hypervisor)

      counter = host.vmware_hypervisor_facet ? :updated : :added

      ipaddress6 = hypervisor.ipaddress6
      ipaddress6 = nil if begin
        IPAddr.new('fe80::/10').include?(ipaddress6)
      rescue StandardError
        false
      end

      hostname = hypervisor.hostname
      domainname = hypervisor.domainname

      unless hostname.present? && domainname.present?
        logger.info "Trying to guess host- and domainname for #{hypervisor.name}."
        hostname, domainname = hypervisor.name.split('.', 2)
      end

      unless hostname.present? && domainname.present?
        logger.error "Could not guess host- and domainname for #{hypervisor.name}. Skipping."
        return false
      end

      result = host.update(
        name: hostname,
        domain: ::Domain.where(name: domainname).first_or_create,
        model: ::Model.where(name: hypervisor.model.strip).first_or_create,
        ip: hypervisor.ipaddress,
        ip6: ipaddress6,
        vmware_hypervisor_facet_attributes: {
          vmware_cluster: cluster,
          cpu_cores: hypervisor.cpu_cores,
          cpu_sockets: hypervisor.cpu_sockets,
          cpu_threads: hypervisor.cpu_threads,
          memory: hypervisor.memory,
          uuid: hypervisor.uuid,
          feature_capabilities: hypervisor.feature_capabilities,
        }
      )
      if result
        increment(counter)
      else
        logger.error "Failed to save host #{host}. Reason: #{host.errors.full_messages.to_sentence}"
      end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

    def hypervisors(cluster)
      @hypervisors[cluster.name.to_sym] ||= compute_resource.hypervisors(cluster_id: cluster.name)
    end

    def find_host_for_hypervisor(hypervisor) # rubocop:disable Metrics/AbcSize
      name = ::ForemanWreckingball::VmwareHypervisorFacet.sanitize_name(hypervisor.name)
      hostname = ::ForemanWreckingball::VmwareHypervisorFacet.sanitize_name([hypervisor.hostname,
                                                                             hypervisor.domainname].join('.'))
      hostname = nil if hostname.blank?

      host = ::ForemanWreckingball::VmwareHypervisorFacet.find_by(uuid: hypervisor.uuid).try(:host)
      host ||= ::Host.find_by(name: hostname) if hostname
      host ||= ::Host.find_by(name: name)
      host ||= create_host_for_hypervisor(hostname || name)
      host
    end

    def create_host_for_hypervisor(name)
      host = ::Host::Managed.new(
        name: name,
        organization: organization,
        location: location,
        managed: false,
        enabled: false
      )
      host.save!
      host
    end

    # rubocop:todo Metrics/AbcSize, Metrics/MethodLength
    def delete_removed_hypervisors(cluster)
      hypervisor_names = hypervisors(cluster).map(&:name)
      hypervisor_uuids = hypervisors(cluster).map(&:uuid)
      delete_query = ::ForemanWreckingball::VmwareHypervisorFacet.joins(:host)
                                                                 .where(vmware_cluster: cluster)
                                                                 .where.not('hosts.name': hypervisor_names)
                                                                 .where.not(uuid: hypervisor_uuids)
      counters[:deleted] = if ActiveRecord::Base.connection.adapter_name.downcase.starts_with?('mysql')
                             ::ForemanWreckingball::VmwareHypervisorFacet.where(id: delete_query.pluck(:id)).delete_all
                           else
                             delete_query.delete_all
                           end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

    def organization
      compute_resource.organizations.first
    end

    def location
      compute_resource.locations.first
    end

    private

    def increment(id)
      counters[id] ||= 0
      counters[id] += 1
    end

    def logger
      ::Foreman::Logging.logger('foreman_wreckingball/import')
    end
  end
end
