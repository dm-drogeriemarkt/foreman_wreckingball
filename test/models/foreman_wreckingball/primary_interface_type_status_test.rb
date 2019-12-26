# frozen_string_literal: true

require 'test_plugin_helper'

module ForemanWreckingball
  class PrimaryInterfaceTypeStatusTest < ActiveSupport::TestCase
    setup do
      User.current = users(:admin)
      Setting::Wreckingball.load_defaults
    end

    should belong_to(:host)

    let(:host) do
      FactoryBot.create(
        :host,
        :managed,
        :with_vmware_facet
      )
    end
    let(:status) { ForemanWreckingball::PrimaryInterfaceTypeStatus.new(host: host) }

    test 'has a host association' do
      status.save!
      assert_equal status, host.public_send(status.class.host_association)
    end

    test '#relevant is only for hosts with a vmware facet' do
      h = FactoryBot.build(:host, :managed)
      refute ForemanWreckingball::PrimaryInterfaceTypeStatus.new(host: h).relevant?
      assert status.relevant?
    end

    test '#relevant is for hosts with a primary interface type' do
      assert status.relevant?
      host.vmware_facet.primary_interface_type = nil
      refute status.relevant?
    end

    describe 'status calculation' do
      test 'is warning when driver is e1000' do
        status.host.vmware_facet.primary_interface_type = 'VirtualE1000'
        assert_equal PrimaryInterfaceTypeStatus::WARNING, status.to_status
      end

      test 'is ok when driver is vmxnet3' do
        status.host.vmware_facet.primary_interface_type = 'VirtualVmxnet3'
        assert_equal PrimaryInterfaceTypeStatus::OK, status.to_status
      end
    end

    describe 'status labels' do
      test 'when driver is e1000' do
        status.status = PrimaryInterfaceTypeStatus::WARNING
        assert_equal 'Using slow E1000 driver', status.to_label
      end

      test 'when driver is vmxnet3' do
        status.status = PrimaryInterfaceTypeStatus::OK
        assert_equal 'OK', status.to_label
      end
    end

    describe 'global status' do
      test 'is warning when driver is not paravirtualized' do
        status.status = PrimaryInterfaceTypeStatus::WARNING
        assert_equal HostStatus::Global::WARN, status.to_global
      end

      test 'is ok when driver is paravirtualized' do
        status.status = PrimaryInterfaceTypeStatus::OK
        assert_equal HostStatus::Global::OK, status.to_global
      end
    end

    describe '#uses_e1000?' do
      test 'is true when primary interface driver is E1000' do
        status.host.vmware_facet.primary_interface_type = 'VirtualE1000'
        assert status.uses_e1000?
      end

      test 'is false when primary interface driver is Vmxnet3' do
        status.host.vmware_facet.primary_interface_type = 'VirtualVmxnet3'
        refute status.uses_e1000?
      end
    end
  end
end
