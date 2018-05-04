# frozen_string_literal: true

require 'test_plugin_helper'

module ForemanWreckingball
  class SpectreV2StatusTest < ActiveSupport::TestCase
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
    let(:status) { ForemanWreckingball::SpectreV2Status.new(host: host) }

    test 'has a host association' do
      status.save!
      assert_equal status, host.public_send(status.class.host_association)
    end

    test '#relevant is only for hosts with a vmware facet' do
      h = FactoryBot.build(:host, :managed)
      refute ForemanWreckingball::ToolsStatus.new(host: h).relevant?
      assert status.relevant?
    end

    test '#relevant is for hosts with cpu features' do
      assert status.relevant?
      host.vmware_facet.cpu_features = []
      refute status.relevant?
    end

    describe 'status calculation' do
      test 'is missing when mitigations are missing' do
        status.stubs(:guest_mitigation_enabled?).returns(false)
        assert_equal SpectreV2Status::MISSING, status.to_status
      end

      test 'is enabled when mitigations are present' do
        status.stubs(:guest_mitigation_enabled?).returns(true)
        assert_equal SpectreV2Status::ENABLED, status.to_status
      end

      test 'is missing when hardware version is ancient' do
        status.stubs(:recent_hw_version?).returns(false)
        assert_equal SpectreV2Status::MISSING, status.to_status
      end
    end

    describe 'status labels' do
      test 'when mitigations are missing' do
        status.status = SpectreV2Status::MISSING
        assert_equal 'Guest Mitigation Missing', status.to_label
      end

      test 'when mitigations are present' do
        status.status = SpectreV2Status::ENABLED
        assert_equal 'Guest Mitigation Enabled', status.to_label
      end
    end

    describe 'global status' do
      test 'is error when mitigations are missing' do
        status.status = SpectreV2Status::MISSING
        assert_equal HostStatus::Global::ERROR, status.to_global
      end

      test 'is ok when mitigations are present' do
        status.status = SpectreV2Status::ENABLED
        assert_equal HostStatus::Global::OK, status.to_global
      end
    end

    describe '#recent_hw_version?' do
      test 'is true when hw version is quite new' do
        assert status.recent_hw_version?
      end

      test 'is false when hw version is ancient' do
        host.vmware_facet.hardware_version = 'vmx-3'
        refute status.recent_hw_version?
      end
    end

    describe '#required_cpu_features_present?' do
      test 'is false when neither cpuid.IBRS, cpuid.IBPB nor cpuid.STIBP is present' do
        host.vmware_facet.cpu_features = ['cpuid.SSE42']
        refute status.required_cpu_features_present?
      end

      test 'is true when cpuid.IBRS is present' do
        host.vmware_facet.cpu_features = ['cpuid.IBRS']
        assert status.required_cpu_features_present?
      end

      test 'is true when cpuid.IBPB is present' do
        host.vmware_facet.cpu_features = ['cpuid.IBPB']
        assert status.required_cpu_features_present?
      end

      test 'is true when cpuid.STIBP is present' do
        host.vmware_facet.cpu_features = ['cpuid.STIBP']
        assert status.required_cpu_features_present?
      end
    end
  end
end
