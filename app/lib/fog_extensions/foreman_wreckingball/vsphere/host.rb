module FogExtensions
  module ForemanWreckingball
    module Vsphere
      module Host
        extend ActiveSupport::Concern

        module Overrides
          def vm_ids
            attributes[:vm_ids] = attributes[:vm_ids].call if attributes[:vm_ids].is_a?(Proc)
            attributes[:vm_ids]
          end
        end

        included do
          prepend Overrides

          attribute :cpu_cores
          attribute :cpu_sockets
          attribute :cpu_threads
          attribute :memory
          attribute :uuid
          attribute :model
          attribute :vendor
          attribute :ipaddress
          attribute :ipaddress6
          attribute :product_name
          attribute :product_version
          attribute :hostname
          attribute :domainname
        end

        def memory_mb
          memory / 1024 / 1024
        end
      end
    end
  end
end
