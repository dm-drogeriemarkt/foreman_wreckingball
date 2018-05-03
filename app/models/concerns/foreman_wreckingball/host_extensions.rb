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
    end

    def action_input_key
      'host'
    end
  end
end
