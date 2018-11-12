# frozen_string_literal: true

class Setting
  class Wreckingball < ::Setting
    def self.load_defaults
      return unless ActiveRecord::Base.connection.table_exists?('settings')
      return unless super

      Setting.transaction do
        [
          set('min_vsphere_hardware_version', N_('Minimum required Hardware version for vSphere VMs'), 13, N_('Hardware version'))
        ].compact.each { |s| Setting::Wreckingball.create s.update(category: 'Setting::Wreckingball') }
      end

      true
    end

    def self.humanized_category
      N_('Wreckingball')
    end
  end
end
