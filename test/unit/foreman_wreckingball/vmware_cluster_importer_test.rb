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

      test 'removes old clusters' do
        old_cluster = FactoryBot.create(:vmware_cluster, compute_resource: compute_resource)
        importer.import!
        refute ForemanWreckingball::VmwareCluster.find_by(id: old_cluster.id)
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
