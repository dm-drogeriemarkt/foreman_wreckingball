# frozen_string_literal: true

module ForemanWreckingball
  module HostExtensions
    extend ActiveSupport::Concern
    include ForemanTasks::Concerns::ActionSubject

    included do
      ForemanWreckingball::Engine::WRECKINGBALL_STATUSES.map(&:constantize).each do |status|
        has_one(status::HOST_ASSOCIATION, class_name: status.to_s,
                                          foreign_key: 'host_id',
                                          inverse_of: :host,
                                          dependent: :destroy)

        scoped_search :relation => status::HOST_ASSOCIATION,
                      :on => :status,
                      :rename => status::HOST_ASSOCIATION.to_s.chomp('_object'),
                      :only_explicit => true,
                      :operators => ['=', '!=', '<>'],
                      :complete_value => status::SEARCH_VALUES
      end

      scope :owned_by_current_user, -> { where(owner_type: 'User', owner_id: User.current.id) }
      scope :owned_by_group_with_current_user, -> { where(owner_type: 'Usergroup', owner_id: User.current.usergroup_ids_with_parents) }
      scope :owned_by_current_user_or_group_with_current_user, -> { owned_by_current_user.or(owned_by_group_with_current_user) }
    end

    def action_input_key
      'host'
    end
  end
end
