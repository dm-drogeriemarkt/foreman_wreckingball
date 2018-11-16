# frozen_string_literal: true

require 'test_plugin_helper'

class Host::ManagedTest < ActiveSupport::TestCase
  should have_one(:vmware_facet)
  should have_one(:vmware_cluster)
  should have_one(:vmware_hypervisor_facet)
  should have_one(:vmware_tools_status_object)
  should have_one(:vmware_operatingsystem_status_object)
  should have_one(:vmware_cpu_hot_add_status_object)
  should have_one(:vmware_spectre_v2_status_object)
  should have_one(:vmware_hardware_version_status_object)

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
      actual = Host::Managed.owned_by_current_user_or_group_with_current_user

      assert_equal expected, actual
    end
  end
end
