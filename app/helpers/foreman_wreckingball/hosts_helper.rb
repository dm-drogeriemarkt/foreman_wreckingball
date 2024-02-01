# frozen_string_literal: true

module ForemanWreckingball
  module HostsHelper
    extend ActiveSupport::Concern

    def classes_for_vmware_status_row(counter)
      return 'pficon-error-circle-o list-view-pf-icon-danger' if (counter[:critical] || 0).positive?
      return 'pficon-warning-triangle-o list-view-pf-icon-warning' if (counter[:warning] || 0).positive?
      'pficon-ok list-view-pf-icon-success'
    end
  end
end
