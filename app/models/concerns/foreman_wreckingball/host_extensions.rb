# frozen_string_literal: true

module ForemanWreckingball
  module HostExtensions
    extend ActiveSupport::Concern
    include ForemanTasks::Concerns::ActionSubject

    included do
      ForemanWreckingball::Engine::WRECKINGBALL_STATUSES.map(&:constantize).each do |status|
        has_one(status.host_association, class_name: status.to_s,
                                         foreign_key: 'host_id',
                                         inverse_of: :host,
                                         dependent: :destroy)
      end

      scope :owned_by_current_user, -> { where(owner_type: 'User', owner_id: User.current.id) }
      scope :owned_by_group_with_current_user, -> { where(owner_type: 'Usergroup', owner_id: User.current.usergroup_ids_with_parents) }
      scope :owned_by_current_user_or_group_with_current_user, -> { owned_by_current_user.or(owned_by_group_with_current_user) }

      def self.reflect_on_environment?
        reflect_on_association(:environment).present?
      end
    end

    def action_input_key
      'host'
    end

    def deduced_vsphere_guest
      return unless architecture && operatingsystem

      selectors = {
        architecture: architecture.name,
        osfamily: operatingsystem.family,
        name: operatingsystem.name,
        major: operatingsystem.major.to_i
      }

      deduced_os = VsphereOsIdentifiers.find_by(selectors)
      deduced_os ||= VsphereOsIdentifiers.find_by(selectors.except(:major))
      deduced_os ||= VsphereOsIdentifiers.find_by(selectors.except(:release))
      deduced_os ||= VsphereOsIdentifiers.find_by(selectors.except(:major, :release))
      deduced_os ||= VsphereOsIdentifiers.find_by(selectors.except(:major, :name))
      deduced_os ||= VsphereOsIdentifiers.find_by(selectors.except(:major, :name, :release))

      deduced_os
    end

    def deduced_vsphere_guest_id
      deduced_vsphere_guest&.id
    end
  end
end
