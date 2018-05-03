# frozen_string_literal: true

require 'test_plugin_helper'

class Host::ManagedTest < ActiveSupport::TestCase
  should have_one(:vmware_facet)
  should have_one(:vmware_cluster)
  should have_one(:vmware_hypervisor_facet)
  should have_one(:vmware_tools_status_object)
  should have_one(:vmware_operatingsystem_status_object)
  should have_one(:vmware_cpu_hot_add_status_object)
end
