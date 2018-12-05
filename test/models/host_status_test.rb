# frozen_string_literal: true

require 'test_plugin_helper'

class HostStatusTest < ActiveSupport::TestCase
  describe '#wreckingball_statuses' do
    test 'returns wreckingball statuses' do
      expected = ForemanWreckingball::Engine::WRECKINGBALL_STATUSES.sort.map(&:constantize)
      actual = HostStatus.wreckingball_statuses.sort_by(&:to_s)
      assert_equal expected, actual
    end
  end

  describe '#find_wreckingball_status_by_host_association' do
    test 'returns expected wreckingball status' do
      expected = ForemanWreckingball::Engine::WRECKINGBALL_STATUSES.first.constantize
      actual = HostStatus.find_wreckingball_status_by_host_association(expected.host_association)

      assert_equal expected, actual
    end
  end
end
