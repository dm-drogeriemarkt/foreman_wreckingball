# frozen_string_literal: true

module ForemanWreckingball
  module VmwareFacetHostExtensions
    extend ActiveSupport::Concern

    # rubocop:disable Metrics/BlockLength
    included do
      has_one :vmware_facet,
        class_name: '::ForemanWreckingball::VmwareFacet',
        foreign_key: :host_id,
        inverse_of: :host, dependent: :destroy

      before_provision :queue_vmware_facet_refresh

      scoped_search on: :hardware_version,
                    relation: :vmware_facet,
                    rename: :vsphere_hardware_version,
                    complete_value: true,
                    only_explicit: true
      scoped_search on: :guest_id,
                    relation: :vmware_facet,
                    rename: :vsphere_guest_id,
                    complete_value: true,
                    only_explicit: true
      scoped_search on: :cpus,
                    relation: :vmware_facet,
                    rename: :vsphere_cpus,
                    complete_value: true,
                    only_explicit: true
      scoped_search on: :corespersocket,
                    relation: :vmware_facet,
                    rename: :vsphere_corespersocket,
                    complete_value: true,
                    only_explicit: true
      scoped_search on: :memory_mb,
                    relation: :vmware_facet,
                    rename: :vsphere_memory_mb,
                    complete_value: true,
                    only_explicit: true
      scoped_search on: :power_state,
                    relation: :vmware_facet,
                    rename: :vsphere_power_state,
                    only_explicit: true,
                    complete_value: ForemanWreckingball::VmwareFacet::VALID_POWER_STATES.map { |status| [status, ForemanWreckingball::VmwareFacet.power_states[status]] }.to_h # rubocop:todo Rails/IndexWith, Layout/LineLength
      scoped_search on: :tools_state,
                    relation: :vmware_facet,
                    rename: :vsphere_tools_state,
                    only_explicit: true,
                    complete_value: ForemanWreckingball::VmwareFacet::VALID_GUEST_STATUSES.map { |status| [status, ForemanWreckingball::VmwareFacet.tools_states[status]] }.to_h # rubocop:todo Rails/IndexWith, Layout/LineLength
    end
    # rubocop:enable Metrics/BlockLength

    def refresh_vmware_facet!
      facet = vmware_facet || build_vmware_facet
      facet.refresh!
      facet.persisted? && facet.refresh_statuses
    end

    def queue_vmware_facet_refresh
      if managed? && compute? && provider == 'VMware'
        User.as_anonymous_admin do
          ForemanTasks.delay(
            ::Actions::ForemanWreckingball::Host::RefreshVmwareFacet,
            { start_at: Time.now.utc + 5.minutes },
            self
          )
        end
      end
      true
    end
  end
end
