# frozen_string_literal: true

require 'integration_test_plugin_helper'

class HostsStatusManagedHostsTest < ActionDispatch::IntegrationTest
  setup do
    Setting::Wreckingball.load_defaults
    Fog.mock!
  end

  let(:organization) { Organization.find_by(name: 'Organization 1') }
  let(:tax_location) { Location.find_by(name: 'Location 1') }
  let(:admin) { users(:admin) }
  let(:cr) do
    FactoryBot.create(
      :vmware_cr,
      uuid: 'test',
      organizations: [organization],
      locations: [tax_location]
    )
  end

  test 'shows missing host without VMware vm' do
    managed_host = FactoryBot.create(:host, :managed, compute_resource: cr, owner: admin, uuid: 1)
    missing_host = FactoryBot.create(:host, :managed, compute_resource: cr, owner: admin, uuid: 2)

    mock_vm = mock('vm')
    mock_vm.stubs(:uuid).returns(managed_host.uuid)
    mock_vm.stubs(:name).returns(managed_host.name)
    Foreman::Model::Vmware.any_instance.stubs(:vms).returns(Array(mock_vm))

    visit status_managed_hosts_dashboard_hosts_path

    list = page.find('#missing_vms')
    assert_includes list.text, missing_host.name
    refute_includes list.text, managed_host.name
  end

  test 'shows duplicate vms with same uuid for a host' do
    managed_host = FactoryBot.create(:host, :managed, compute_resource: cr, owner: admin, uuid: 1)

    mock1_vm = mock('vm1')
    mock1_vm.stubs(:uuid).returns(managed_host.uuid)
    mock1_vm.stubs(:name).returns('foo01.example.com')
    mock2_vm = mock('vm2')
    mock2_vm.stubs(:uuid).returns(managed_host.uuid)
    mock2_vm.stubs(:name).returns('foo02.example.com')
    Foreman::Model::Vmware.any_instance.stubs(:vms).returns([mock1_vm, mock2_vm])

    visit status_managed_hosts_dashboard_hosts_path

    list = page.find('#duplicate_vms')
    assert_includes list.text, 'foo01.example.com'
    assert_includes list.text, 'foo02.example.com'
  end

  test 'shows hosts with vm associated with a different compute resource' do
    other_cr = FactoryBot.create(
      :vmware_cr,
      uuid: 'bla',
      organizations: [organization],
      locations: [tax_location]
    )

    # Host 2 is associated to other_cr, but shows up on cr
    # Host 1 and 3 are correctly associated.
    managed1_host = FactoryBot.create(:host, :managed, compute_resource: cr, owner: admin, uuid: 1)
    managed2_host = FactoryBot.create(:host, :managed, compute_resource: other_cr, owner: admin, uuid: 2)
    managed3_host = FactoryBot.create(:host, :managed, compute_resource: other_cr, owner: admin, uuid: 3)

    mock1_vm = mock('vm1')
    mock1_vm.stubs(:uuid).returns(managed1_host.uuid)
    mock1_vm.stubs(:name).returns(managed1_host.name)
    mock2_vm = mock('vm2')
    mock2_vm.stubs(:uuid).returns(managed2_host.uuid)
    mock2_vm.stubs(:name).returns(managed2_host.name)
    mock3_vm = mock('vm3')
    mock3_vm.stubs(:uuid).returns(managed3_host.uuid)
    mock3_vm.stubs(:name).returns(managed3_host.name)

    cr.stubs(:vms).returns([mock1_vm, mock2_vm])
    other_cr.stubs(:vms).returns([mock3_vm])

    ComputeResource.stubs(:where).returns([cr, other_cr])

    visit status_managed_hosts_dashboard_hosts_path

    list = page.find('#different_vms')
    refute_includes list.text, managed1_host.name
    assert_includes list.text, managed2_host.name
    refute_includes list.text, managed3_host.name
  end
end
