# frozen_string_literal: true

require 'test_plugin_helper'

module ForemanWreckingball
  class VmwareClusterImporterTest < ActiveSupport::TestCase
    setup do
      User.current = users(:admin)
      Fog.mock!
    end
    teardown { Fog.unmock! }

    let(:compute_resource) { FactoryBot.create(:vmware_cr, :uuid => 'Solutions') }
    let(:importer) do
      VmwareClusterImporter.new(
        compute_resource: compute_resource
      )
    end

    describe '#import!' do
      test 'imports clusters' do
        importer.import!
        clusters = ForemanWreckingball::VmwareCluster.pluck(:name)
        assert_includes clusters, 'Solutionscluster'
        assert_includes clusters, 'Problemscluster'
        assert_includes clusters, 'Nested/Lastcluster'
      end

      test 'removes old clusters without associated records' do
        old_cluster = FactoryBot.create(:vmware_cluster,
                                        :with_hosts,
                                        :with_vmware_facets,
                                        :with_vmware_hypervisor_facets,
                                        compute_resource: compute_resource)

        compute_resource_id = old_cluster.compute_resource.id
        host_ids = old_cluster.hosts.pluck(:id)
        vmware_facet_ids = old_cluster.vmware_facets.pluck(:id)
        vmware_hypervisor_facet_ids = old_cluster.vmware_hypervisor_facets.pluck(:id)

        importer.import!
        refute ForemanWreckingball::VmwareCluster.find_by(id: old_cluster.id)

        assert Foreman::Model::Vmware.find_by(id: compute_resource_id)
        assert_equal host_ids.count, Host.where(id: host_ids).count
        assert_equal vmware_facet_ids.count, ForemanWreckingball::VmwareFacet.where(id: vmware_facet_ids).count
        assert_equal vmware_hypervisor_facet_ids.count, ForemanWreckingball::VmwareHypervisorFacet.where(id: vmware_hypervisor_facet_ids).count
      end

      test 'can be run twice without a change' do
        importer.import!
        before = ForemanWreckingball::VmwareCluster.pluck(:updated_at)
        importer.import!
        after = ForemanWreckingball::VmwareCluster.pluck(:updated_at)
        assert_equal before, after
      end
    end
  end
end
