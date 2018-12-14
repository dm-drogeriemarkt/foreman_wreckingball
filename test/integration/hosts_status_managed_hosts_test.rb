# frozen_string_literal: true

require 'pry'

require 'integration_test_plugin_helper'

class HostsStatusManagedHostsTest < ActionDispatch::IntegrationTest
  setup do
    Setting::Wreckingball.load_defaults
  end

  let(:admin) { users(:admin) }

  test 'shows missing host without VMware vm' do
    managed_host = FactoryBot.create(:host, :managed, owner: admin, uuid: 1)
    missing_host = FactoryBot.create(:host, :managed, owner: admin)

    mock_vm = mock('vm')
    mock_vm.expects(:uuid).returns(managed_host.uuid)
    Foreman::Model::Vmware.any_instance.stubs(:vms).returns(Array(mock_vm))

    visit status_managed_hosts_dashboard_hosts_path

    binding.pry
  end
end
