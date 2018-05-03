# frozen_string_literal: true

module ForemanWreckingball
  module HostsHelperExtensions
    extend ActiveSupport::Concern

    def classes_for_vmware_status_row(counter)
      return 'pficon-error-circle-o list-view-pf-icon-danger' if (counter[:critical] || 0).positive?
      return 'pficon-warning-triangle-o list-view-pf-icon-warning' if (counter[:warning] || 0).positive?
      'pficon-ok list-view-pf-icon-success'
    end

    def vmware_status_counter(hosts, status_object)
      count = hosts.map do |host|
        host.public_send(status_object).to_global
      end.group_by do |status|
        status
      end.each_with_object({}) do |(status, items), hash|
        hash[status] = items.size
      end
      {
        :ok => count[HostStatus::Global::OK] || 0,
        :warning => count[HostStatus::Global::WARN] || 0,
        :critical => count[HostStatus::Global::ERROR] || 0
      }
    end
  end
end
