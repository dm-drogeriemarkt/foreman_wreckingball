# frozen_string_literal: true

require 'test_plugin_helper'

module Actions
  module ForemanWreckingball
    describe Actions::ForemanWreckingball::BulkRemediate do
      include Dynflow::Testing

      let(:action_class) { ::Actions::ForemanWreckingball::BulkRemediate }
      let(:bulk_action) { ::Actions::BulkAction }
      let(:action) { create_action(action_class) }

      setup do
        FactoryBot.create_list(:host, 2, :managed, :with_wreckingball_statuses)
      end

      it 'plans remediate action' do
        ::ForemanWreckingball::Engine::WRECKINGBALL_STATUSES.map(&:constantize)
                                                            .select(&:supports_remediate?)
                                                            .each do |status|
          statuses = HostStatus::Status.where(type: status.to_s)
          plan_action(action, statuses)

          assert_action_planed_with(action, bulk_action, status.remediate_action, statuses.map(&:host))
        end
      end
    end
  end
end
