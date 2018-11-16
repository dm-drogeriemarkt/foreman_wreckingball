# frozen_string_literal: true

module ForemanWreckingball
  module UsergroupExtensions
    def parent_usergroup_ids
      @parent_usergroup_ids ||= get_parent_ids(parent_ids)
    end

    private

    def get_parent_ids(member_ids, result_ids = parent_ids)
      return result_ids if member_ids.empty?

      new_parent_ids = UsergroupMember.usergroup_memberships.where(member_id: member_ids).pluck(:usergroup_id)
      get_parent_ids(new_parent_ids, result_ids + new_parent_ids)
    end
  end
end
