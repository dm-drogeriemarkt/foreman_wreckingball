# frozen_string_literal: true

require 'test_plugin_helper'

module ForemanWreckingball
  class HardwareVersionStatusTest < ActiveSupport::TestCase
    setup do
      User.current = users(:admin)
    end

    should belong_to(:host)

    let(:host) do
      FactoryBot.create(
        :host,
        :managed,
        :with_vmware_facet
      )
    end
    let(:status) { ForemanWreckingball::HardwareVersionStatus.new(host: host) }

    test 'has a host association' do
      status.save!
      assert_equal status, host.public_send(status.class.host_association)
    end

    test '#relevant is only for hosts with a vmware facet' do
      h = FactoryBot.build(:host, :managed)
      assert_not ForemanWreckingball::ToolsStatus.new(host: h).relevant?
      assert status.relevant?
    end

    test '#relevant is for hosts with a hardware version' do
      assert status.relevant?
      host.vmware_facet.hardware_version = nil
      assert_not status.relevant?
    end

    describe 'status calculation' do
      test 'is out of date when version is too old' do
        status.host.vmware_facet.hardware_version = 'vmx-9'
        assert_equal HardwareVersionStatus::OUTOFDATE, status.to_status
      end

      test 'is ok when version is recent enough' do
        status.host.vmware_facet.hardware_version = 'vmx-13'
        assert_equal HardwareVersionStatus::OK, status.to_status
      end
    end

    describe 'status labels' do
      test 'when version is out of date' do
        status.status = HardwareVersionStatus::OUTOFDATE
        assert_equal 'Out of date', status.to_label
      end

      test 'when version is recent' do
        status.status = HardwareVersionStatus::OK
        assert_equal 'OK', status.to_label
      end
    end

    describe 'global status' do
      test 'is warning when version is out of date' do
        status.status = HardwareVersionStatus::OUTOFDATE
        assert_equal HostStatus::Global::WARN, status.to_global
      end

      test 'is ok when version is recent' do
        status.status = HardwareVersionStatus::OK
        assert_equal HostStatus::Global::OK, status.to_global
      end
    end

    describe '#recent_hw_version?' do
      test 'is true when hw version is new' do
        status.host.vmware_facet.hardware_version = 'vmx-13'
        assert status.recent_hw_version?
      end

      test 'is false when hw version is ancient' do
        status.host.vmware_facet.hardware_version = 'vmx-3'
        assert_not status.recent_hw_version?
      end
    end
  end
end
