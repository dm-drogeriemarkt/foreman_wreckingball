module ForemanWreckingball
  module HostExtensions
    extend ActiveSupport::Concern

    included do
      has_one :vmware_tools_status_object, :class_name => 'ForemanWreckingball::ToolsStatus', :foreign_key => 'host_id'
      has_one :vmware_operatingsystem_status_object, :class_name => 'ForemanWreckingball::OperatingsystemStatus', :foreign_key => 'host_id'
      has_one :vmware_cpu_hot_add_status_object, :class_name => 'ForemanWreckingball::CpuHotAddStatus', :foreign_key => 'host_id'
    end

    def action_input_key
      'host'
    end
  end
end
