module FogExtensions
  module ForemanWreckingball
    module Vsphere
      module Real
        extend ActiveSupport::Concern

        module Overrides
          def host_system_attribute_mapping
            super.merge(
              feature_capabilities: 'config.featureCapability'
            )
          end

          def list_hosts(filters = {})
            super.map { |h| h[:feature_capabilities] = h[:feature_capabilities].map(&:key); h }
          end
        end

        included do
          prepend Overrides
        end
      end
    end
  end
end
