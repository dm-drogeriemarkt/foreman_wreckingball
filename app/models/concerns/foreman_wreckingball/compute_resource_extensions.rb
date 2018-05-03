# frozen_string_literal: true

module ForemanWreckingball
  module ComputeResourceExtensions
    extend ActiveSupport::Concern
    include ForemanTasks::Concerns::ActionSubject

    included do
      has_many :vmware_clusters, :class_name => 'ForemanWreckingball::VmwareCluster',
                                 :inverse_of => :compute_resource, :dependent => :destroy
    end

    def action_input_key
      'compute_resource'
    end
  end
end
