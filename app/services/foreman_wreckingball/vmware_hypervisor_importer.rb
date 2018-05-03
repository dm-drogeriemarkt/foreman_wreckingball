# frozen_string_literal: true

module ForemanWreckingball
  class VmwareHypervisorImporter
    delegate :logger, :to => :Rails
    attr_accessor :compute_resource, :counters

    def initialize(options = {})
      @compute_resource = options.fetch(:compute_resource)
      @hypervisors = {}
      @counters = {}
    end

    def import!
      logger.info "Can not determine organization for compute resource #{compute_resource}." if SETTINGS[:organizations_enabled]
      compute_resource.refresh_cache
      compute_resource.vmware_clusters.each do |cluster|
        import_hypervisors(cluster)
      end
      logger.info("Import hypervisors for '#{compute_resource}' completed. Added: #{counters[:added] || 0}, Updated: #{counters[:updated] || 0}, Deleted: #{counters[:deleted] || 0} hypervisors") # rubocop:disable Metrics/LineLength
    end

    def import_hypervisors(cluster)
      hypervisors(cluster).each do |hypervisor|
        import_hypervisor(cluster, hypervisor)
      end
    end

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
        :name => hostname,
        :domain => ::Domain.where(:name => domainname).first_or_create,
        :model => ::Model.where(:name => hypervisor.model.strip).first_or_create,
        :ip => hypervisor.ipaddress,
        :ip6 => ipaddress6,
        :vmware_hypervisor_facet_attributes => {
          :vmware_cluster => cluster,
          :cpu_cores => hypervisor.cpu_cores,
          :cpu_sockets => hypervisor.cpu_sockets,
          :cpu_threads => hypervisor.cpu_threads,
          :memory => hypervisor.memory,
          :uuid => hypervisor.uuid
        }
      )
      if result
        increment_counter(counter)
      else
        logger.error "Failed to save host #{host}. Reason: #{host.errors.full_messages.to_sentence}"
      end
    end

    def hypervisors(cluster)
      @hypervisors[cluster.name.to_sym] ||= compute_resource.hypervisors(:cluster_id => cluster.name)
    end

    def find_host_for_hypervisor(hypervisor)
      name = ::ForemanWreckingball::VmwareHypervisorFacet.sanitize_name(hypervisor.name)
      hostname = ::ForemanWreckingball::VmwareHypervisorFacet.sanitize_name([hypervisor.hostname, hypervisor.domainname].join('.'))
      hostname = nil if hostname.blank?
      katello_name = katello_hypervisor_hostname(hostname || name)
      katello_uuid = katello_hypervisor_hostname(hypervisor.uuid)

      host = ::ForemanWreckingball::VmwareHypervisorFacet.find_by(:uuid => hypervisor.uuid).try(:host)
      host ||= ::Host.find_by(:name => hostname) if hostname
      host ||= ::Host.find_by(:name => name)
      host ||= ::Host.find_by(:name => katello_name) if katello_name
      host ||= ::Host.find_by(:name => katello_uuid) if katello_uuid
      host ||= create_host_for_hypervisor(hostname || name)
      host
    end

    def create_host_for_hypervisor(name)
      host = ::Host::Managed.new(:name => name, :organization => organization,
                                 :location => location, :managed => false, :enabled => false)
      host.save!
      host
    end

    def organization
      return unless SETTINGS[:organizations_enabled]
      compute_resource.organizations.first
    end

    def location
      return unless SETTINGS[:locations_enabled]
      compute_resource.locations.first
    end

    def katello_hypervisor_hostname(hostname)
      return unless organization
      "virt-who-#{hostname}-#{organization.id}"
    end

    private

    def increment_counter(id)
      counters[id] ||= 0
      counters[id] += 1
    end
  end
end
