# frozen_string_literal: true

module FogExtensions
  module ForemanWreckingball
    module Vsphere
      module Mock
        extend ActiveSupport::Concern

        def vm_upgrade_hardware(*)
          { 'task_state' => 'success' }
        end
      end
    end
  end
end
