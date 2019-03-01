# frozen_string_literal: true

module ForemanWreckingball
  module Hosts
    module StatusManagedHostsDashboardHelper
      def hostname_or_link_to(host)
        hash_for_host_path = hash_for_host_path(id: host)
        if User.current.allowed_to?(hash_for_host_path)
          link_to_if_authorized(host.name, hash_for_host_path)
        else
          host.name
        end
      end
    end
  end
end
