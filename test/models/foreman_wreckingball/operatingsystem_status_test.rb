# frozen_string_literal: true

require 'test_plugin_helper'

module ForemanWreckingball
  class OperatingsystemStatusTest < ActiveSupport::TestCase
    setup do
      User.current = users(:admin)
    end

    should belong_to(:host)

    let(:operatingsystem) do
      FactoryBot.create(
        :operatingsystem,
        architectures: [architectures(:x86_64)],
        major: 6,
        minor: 1,
        type: 'Redhat',
        name: 'RedHat'
      )
    end
    let(:host) do
      FactoryBot.create(
        :host,
        :managed,
        :with_vmware_facet,
        architecture: architectures(:x86_64),
        operatingsystem: operatingsystem
      )
    end
    let(:status) { ForemanWreckingball::OperatingsystemStatus.new(host: host) }

    test 'has a host association' do
      status.save!
      assert_equal status, host.public_send(status.class.host_association)
    end

    test '#relevant is only for hosts with a vmware facet' do
      h = FactoryBot.build(:host, :managed)
      refute ForemanWreckingball::ToolsStatus.new(host: h).relevant?
      assert status.relevant?
    end

    describe 'status calculation' do
      test 'when os does not match' do
        status.stubs(:os_matches_identifier?).returns(false)
        assert_equal OperatingsystemStatus::MISMATCH, status.to_status
      end

      test 'when os matches' do
        status.stubs(:os_matches_identifier?).returns(true)
        assert_equal OperatingsystemStatus::OK, status.to_status
      end
    end

    describe 'status labels' do
      test 'when os does not match' do
        status.status = OperatingsystemStatus::MISMATCH
        assert_equal 'VM OS is incorrect', status.to_label
      end

      test 'when os matches' do
        status.status = OperatingsystemStatus::OK
        assert_equal 'OK', status.to_label
      end
    end

    describe 'global status' do
      test 'when os does not match' do
        status.status = OperatingsystemStatus::MISMATCH
        assert_equal HostStatus::Global::WARN, status.to_global
      end

      test 'when os matches' do
        status.status = OperatingsystemStatus::OK
        assert_equal HostStatus::Global::OK, status.to_global
      end
    end

    describe '#os_matches_identifier?' do
      test 'when architecture does not match' do
        host.architecture = architectures(:sparc)
        refute status.os_matches_identifier?
      end

      test 'when operatingsystem does not match' do
        host.operatingsystem = operatingsystems(:ubuntu1210)
        refute status.os_matches_identifier?
      end

      test 'when architecture, osfamily, name and major match' do
        assert status.os_matches_identifier?
      end
    end
  end
end
