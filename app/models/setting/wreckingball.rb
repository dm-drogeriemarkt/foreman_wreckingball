# frozen_string_literal: true

class Setting
  class Wreckingball < ::Setting
    def self.default_settings
      [
        set('min_vsphere_hardware_version', N_('Minimum required Hardware version for vSphere VMs'), 13, N_('Hardware version'))
      ]
    end

    def self.load_defaults
      return unless ActiveRecord::Base.connection.table_exists?('settings')
      return unless super

      Setting.transaction do
        default_settings.compact.each { |s| Setting::Wreckingball.create s.update(category: 'Setting::Wreckingball') }
      end

      true
    end

    def self.humanized_category
      N_('Wreckingball')
    end
  end
end
