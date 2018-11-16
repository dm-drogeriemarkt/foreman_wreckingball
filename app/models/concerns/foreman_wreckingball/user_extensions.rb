# frozen_string_literal: true

module ForemanWreckingball
  module UserExtensions
    def usergroup_ids_with_parents
      ids = []
      ids << usergroup_ids
      ids << usergroups.map(&:parent_usergroup_ids)
      ids.flatten.uniq
    end
  end
end
