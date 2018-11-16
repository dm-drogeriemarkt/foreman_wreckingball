# frozen_string_literal: true

module ForemanWreckingball
  module HostExtensions
    extend ActiveSupport::Concern
    include ForemanTasks::Concerns::ActionSubject

    included do
      has_one :vmware_tools_status_object,
              :class_name => 'ForemanWreckingball::ToolsStatus',
              :foreign_key => 'host_id',
              :inverse_of => :host,
              :dependent => :destroy
      has_one :vmware_operatingsystem_status_object,
              :class_name => 'ForemanWreckingball::OperatingsystemStatus',
              :foreign_key => 'host_id',
              :inverse_of => :host,
              :dependent => :destroy
      has_one :vmware_cpu_hot_add_status_object,
              :class_name => 'ForemanWreckingball::CpuHotAddStatus',
              :foreign_key => 'host_id',
              :inverse_of => :host,
              :dependent => :destroy
      has_one :vmware_spectre_v2_status_object,
              :class_name => 'ForemanWreckingball::SpectreV2Status',
              :foreign_key => 'host_id',
              :inverse_of => :host,
              :dependent => :destroy
      has_one :vmware_hardware_version_status_object,
              :class_name => 'ForemanWreckingball::HardwareVersionStatus',
              :foreign_key => 'host_id',
              :inverse_of => :host,
              :dependent => :destroy

      scope :owned_by_current_user, -> { where(owner_type: 'User', owner_id: User.current.id) }
      scope :owned_by_group_with_current_user, -> { where(owner_type: 'Usergroup', owner_id: User.current.usergroup_ids_with_parents) }
      scope :owned_by_current_user_or_group_with_current_user, -> { owned_by_current_user.or(owned_by_group_with_current_user) }
    end

    def action_input_key
      'host'
    end
  end
end
