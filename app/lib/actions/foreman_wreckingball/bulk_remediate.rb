# frozen_string_literal: true

module Actions
  module ForemanWreckingball
    class BulkRemediate < Actions::Base
      def plan(statuses)
        sequence do
          statuses.group_by(&:class).each do |statuses_klass, statuses_list|
            plan_action(::Actions::BulkAction, statuses_klass.remediate_action, statuses_list.map(&:host)) if statuses_klass.respond_to?(:remediate_action)
          end
        end
      end

      def run
        # dummy run phase to save input
      end

      def resource_locks
        :link
      end

      def humanized_name
        _('Bulk remediate')
      end
    end
  end
end
