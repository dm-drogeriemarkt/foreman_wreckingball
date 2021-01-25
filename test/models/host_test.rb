# frozen_string_literal: true

require 'test_plugin_helper'

class Host::ManagedTest < ActiveSupport::TestCase
  should have_one(:vmware_facet)
  should have_one(:vmware_cluster)
  should have_one(:vmware_hypervisor_facet)

  HostStatus.wreckingball_statuses.each do |status|
    should have_one(status.host_association)
  end

  describe '#owned_by_current_user_or_group_with_current_user' do
    test 'returns only hosts owned by current user' do
      usergroup_with_user = FactoryBot.create(:usergroup, users: [User.current], usergroups: [FactoryBot.create(:usergroup, users: [])])

      FactoryBot.create :host, :managed, owner: FactoryBot.create(:user)
      FactoryBot.create :host, :managed, owner: FactoryBot.create(:usergroup, users: [])
      FactoryBot.create :host, :managed, owner: usergroup_with_user.usergroups.first

      expected = [
        FactoryBot.create(:host, :managed, owner: User.current),
        FactoryBot.create(:host, :managed, owner: usergroup_with_user),
        FactoryBot.create(:host, :managed, owner: FactoryBot.create(:usergroup, usergroups: [usergroup_with_user]))
      ]
      actual = Host::Managed.owned_by_current_user_or_group_with_current_user.all

      assert_same_elements expected, actual
    end
  end

  context 'scoped search' do
    setup do
      @host = FactoryBot.create(:host, :with_vmware_facet)
    end

    test 'search by hardware_version' do
      hosts = Host.search_for('vsphere_hardware_version = vmx-10')
      assert_includes hosts, @host
    end

    test 'search by power_state' do
      hosts = Host.search_for('vsphere_power_state = poweredOn')
      assert_includes hosts, @host
    end

    test 'search by tools_state' do
      hosts = Host.search_for('vsphere_tools_state = toolsOk')
      assert_includes hosts, @host
    end

    test 'search by guest_id' do
      hosts = Host.search_for('vsphere_guest_id = rhel6_64Guest')
      assert_includes hosts, @host
    end

    test 'search by cpus' do
      hosts = Host.search_for('vsphere_cpus = 2')
      assert_includes hosts, @host
    end

    test 'search by corespersocket' do
      hosts = Host.search_for('vsphere_corespersocket = 1')
      assert_includes hosts, @host
    end

    test 'search by memory_mb' do
      hosts = Host.search_for('vsphere_memory_mb = 8192')
      assert_includes hosts, @host
    end
  end
end
