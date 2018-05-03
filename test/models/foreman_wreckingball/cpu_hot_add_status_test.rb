# frozen_string_literal: true

require 'test_plugin_helper'

module ForemanWreckingball
  class CpuHotAddStatusTest < ActiveSupport::TestCase
    setup do
      User.current = users(:admin)
    end

    should belong_to(:host)

    let(:host) do
      FactoryBot.create(:host, :managed, :with_vmware_facet)
    end
    let(:status) { ForemanWreckingball::CpuHotAddStatus.new(host: host) }

    test 'has a host association' do
      status.save!
      assert_equal status, host.public_send(status.class.host_association)
    end

    describe 'status labels' do
      test 'with possible performance degration' do
        status.status = CpuHotAddStatus::PERFORMANCE_DEGRATION
        assert_equal 'Possible performance degration', status.to_label
      end

      test 'without performance degration' do
        status.status = CpuHotAddStatus::OK
        assert_equal 'No Impact', status.to_label
      end
    end

    describe 'global status' do
      test 'with possible performance degration' do
        status.status = CpuHotAddStatus::PERFORMANCE_DEGRATION
        assert_equal HostStatus::Global::ERROR, status.to_global
      end

      test 'without performance degration' do
        status.status = CpuHotAddStatus::OK
        assert_equal HostStatus::Global::OK, status.to_global
      end
    end

    describe '#performance_degration?' do
      context 'with cpu hot add disabled' do
        setup do
          host.vmware_facet.cpu_hot_add = false
        end

        test 'status is not relevant' do
          refute status.relevant?
        end

        test 'no performance degration is indicated' do
          refute status.performance_degration?
        end
      end

      context 'with cpu hot add enabled' do
        setup do
          host.vmware_facet.cpu_hot_add = true
        end

        test 'status is relevant' do
          assert status.relevant?
        end

        test 'no performance degration is indicated' do
          FactoryBot.create(:vmware_hypervisor_facet, cpu_cores: 4, vmware_cluster: host.vmware_facet.vmware_cluster)
          host.vmware_facet.cpus = 100
          assert status.performance_degration?
        end
      end
    end

    describe '#hypervisor_min_cores' do
      test 'returns the minimum core count from all hypervisors in the same cluster' do
        FactoryBot.create(:vmware_hypervisor_facet, cpu_cores: 4, vmware_cluster: host.vmware_facet.vmware_cluster)
        FactoryBot.create(:vmware_hypervisor_facet, cpu_cores: 8, vmware_cluster: host.vmware_facet.vmware_cluster)
        status.host.reload
        assert_equal 4, status.hypervisor_min_cores
      end
    end
  end
end
