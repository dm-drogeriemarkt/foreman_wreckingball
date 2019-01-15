# frozen_string_literal: true

module ForemanWreckingball
  module HostStatusExtensions
    def wreckingball_statuses
      status_registry.select { |s| s.to_s.start_with?('ForemanWreckingball') }
    end

    def find_wreckingball_status_by_host_association(host_association)
      wreckingball_statuses.find { |s| s.host_association.to_s == host_association.to_s }
    end
  end
end
