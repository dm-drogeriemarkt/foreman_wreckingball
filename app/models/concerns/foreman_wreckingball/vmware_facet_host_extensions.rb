# frozen_string_literal: true

module ForemanWreckingball
  module VmwareFacetHostExtensions
    extend ActiveSupport::Concern

    included do
      has_one :vmware_facet, :class_name => '::ForemanWreckingball::VmwareFacet', :foreign_key => :host_id, :inverse_of => :host, :dependent => :destroy

      before_provision :queue_vmware_facet_refresh
    end

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
            { :start_at => Time.now.utc + 5.minutes },
            self
          )
        end
      end
      true
    end
  end
end
