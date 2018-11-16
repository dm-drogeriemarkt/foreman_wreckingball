# frozen_string_literal: true

require 'test_plugin_helper'

class UsergroupTest < ActiveSupport::TestCase
  describe '#parent_usergroup_ids' do
    it 'returns the ids of all parents of a usergroup' do
      child = FactoryBot.create(:usergroup)

      subject = FactoryBot.create(:usergroup, usergroups: [child])

      parent1 = FactoryBot.create(:usergroup, usergroups: [subject])
      parent2 = FactoryBot.create(:usergroup, usergroups: [parent1])
      parent3 = FactoryBot.create(:usergroup, usergroups: [parent1])

      assert_equal subject.parent_usergroup_ids, [parent1, parent2, parent3].map(&:id)
    end

    it 'returns empty array if usergroup has no parents' do
      subject = FactoryBot.create(:usergroup)

      assert_equal subject.parent_usergroup_ids, []
    end
  end
end
