# frozen_string_literal: true

module FogExtensions
  module ForemanWreckingball
    module Vsphere
      module Host
        extend ActiveSupport::Concern

        included do
          attribute :feature_capabilities
        end
      end
    end
  end
end
