# frozen_string_literal: true

require 'test_plugin_helper'

class HostStatusTest < ActiveSupport::TestCase
  WRECKINGBALL_STATUSES = [
    ForemanWreckingball::ToolsStatus,
    ForemanWreckingball::OperatingsystemStatus,
    ForemanWreckingball::SpectreV2Status,
    ForemanWreckingball::CpuHotAddStatus,
    ForemanWreckingball::HardwareVersionStatus
  ].freeze

  describe '#wreckingball_statuses' do
    test 'returns wreckingball statuses' do
      assert_equal WRECKINGBALL_STATUSES.sort_by(&:to_s), HostStatus.wreckingball_statuses.sort_by(&:to_s)
    end
  end

  describe '#find_wreckingball_status_by_host_association' do
    test 'returns expected wreckingball status' do
      expected = WRECKINGBALL_STATUSES.first
      actual = HostStatus.find_wreckingball_status_by_host_association(expected.host_association)

      assert_equal expected, actual
    end
  end
end
