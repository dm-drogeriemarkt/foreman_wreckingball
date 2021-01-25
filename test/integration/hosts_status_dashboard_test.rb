# frozen_string_literal: true

require 'integration_test_plugin_helper'

class HostsStatusDashboardTest < ActionDispatch::IntegrationTest
  setup do
    Setting::Wreckingball.load_defaults
  end

  test 'shows different vmware host statuses' do
    FactoryBot.create_list(:host, 10)
    FactoryBot.create_list(:vmware_tools_status, 1)
    FactoryBot.create_list(:vmware_operatingsystem_status, 2)
    FactoryBot.create_list(:vmware_cpu_hot_add_status, 3)
    FactoryBot.create_list(:vmware_spectre_v2_status, 4, :with_enabled)
    FactoryBot.create_list(:vmware_spectre_v2_status, 5, :with_missing)
    FactoryBot.create_list(:vmware_hardware_version_status, 6, :with_ok_status)
    FactoryBot.create_list(:vmware_hardware_version_status, 7, :with_out_of_date_status)

    User.current = users(:admin)
    visit status_dashboard_hosts_path

    lists = find_all('div.list-view-pf-main-info')

    # VMWare Tools
    assert_includes lists[0].text, '1 OK'
    assert_includes lists[0].text, '0 Warning'
    assert_includes lists[0].text, '0 Critical'

    # VMWare Operating System
    assert_includes lists[1].text, '2 OK'
    assert_includes lists[1].text, '0 Warning'
    assert_includes lists[1].text, '0 Critical'

    # VMWare CPU Hot Plug
    assert_includes lists[2].text, '3 OK'
    assert_includes lists[2].text, '0 Warning'
    assert_includes lists[2].text, '0 Critical'

    # VMWare Spectre V2
    assert_includes lists[3].text, '4 OK'
    assert_includes lists[3].text, '0 Warning'
    assert_includes lists[3].text, '5 Critical'

    # VMWare Hardware Version
    assert_includes lists[4].text, '6 OK'
    assert_includes lists[4].text, '7 Warning'
    assert_includes lists[4].text, '0 Critical'
  end
end
