# frozen_string_literal: true

module ForemanWreckingball
  module StatusesHelper
    def status_actions(host_association, owned_only, supports_remediate)
      actions = []
      actions << display_link_if_authorized(_('Refresh'),
                                            hash_for_refresh_status_dashboard_hosts_path,
                                            title: _('Refresh Data'),
                                            method: :put)
      if supports_remediate
        actions << display_link_if_authorized(_('Remediate All'),
                                              hash_for_schedule_remediate_hosts_path,
                                              'data-host-association': host_association,
                                              'data-owned-only': owned_only,
                                              onClick: 'show_modal(this); return false;')
      end
      actions.reject(&:blank?)
    end
  end
end
