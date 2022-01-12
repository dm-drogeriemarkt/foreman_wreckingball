# frozen_string_literal: true

require 'test_plugin_helper'

module ForemanWreckingball
  class ToolsStatusTest < ActiveSupport::TestCase
    setup do
      User.current = users(:admin)
    end

    should belong_to(:host)

    let(:host) { FactoryBot.create(:host, :with_vmware_facet) }
    let(:status) { ForemanWreckingball::ToolsStatus.new(host: host) }

    test 'has a host association' do
      status.save!
      assert_equal status, host.public_send(status.class.host_association)
    end

    test '#relevant? is only for hosts not in build mode' do
      host.build = false
      assert status.relevant?

      host.build = true
      refute status.relevant?
    end

    test '#relevant is only for hosts with a vmware facet' do
      h = FactoryBot.build(:host, :managed)
      refute ForemanWreckingball::ToolsStatus.new(host: h).relevant?
    end

    describe 'status calculation' do
      setup do
        Host::Managed.any_instance.stubs(:supports_power?).returns(true)
      end

      test 'when host is powered down' do
        host.vmware_facet.update(power_state: 'poweredOff')
        assert_equal ForemanWreckingball::ToolsStatus::POWERDOWN, status.to_status
      end

      test 'when host is powered on' do
        assert_equal 2, status.to_status
      end
    end

    describe 'status labels' do
      test 'shows a powered down host' do
        status.status = ForemanWreckingball::ToolsStatus::POWERDOWN
        assert_equal 'Powered down', status.to_label
      end

      test 'shows ok message' do
        status.status = ForemanWreckingball::ToolsStatus::TOOLS_OK
        assert_equal 'OK', status.to_label
      end

      test 'shows not installed message' do
        status.status = ForemanWreckingball::ToolsStatus::TOOLS_NOT_INSTALLED
        assert_equal 'Not installed', status.to_label
      end

      test 'shows not running message' do
        status.status = ForemanWreckingball::ToolsStatus::TOOLS_NOT_RUNNING
        assert_equal 'Not running', status.to_label
      end

      test 'shows out of date message' do
        status.status = ForemanWreckingball::ToolsStatus::TOOLS_OLD
        assert_equal 'Out of date', status.to_label
      end
    end
  end
end
