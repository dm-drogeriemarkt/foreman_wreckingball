# frozen_string_literal: true

require 'test_plugin_helper'

module ForemanWreckingball
  class VmwareHypervisorImporterTest < ActiveSupport::TestCase
    setup do
      User.current = users(:admin)
      Fog.mock!
    end
    teardown { Fog.unmock! }

    let(:organization) do
      Organization.find_by(name: 'Organization 1')
    end
    let(:tax_location) do
      Location.find_by(name: 'Location 1')
    end
    let(:compute_resource) do
      FactoryBot.create(
        :vmware_cr,
        uuid: 'Solutions',
        organizations: [organization],
        locations: [tax_location]
      )
    end
    let(:cluster) do
      FactoryBot.create(
        :vmware_cluster,
        name: 'Solutionscluster',
        compute_resource: compute_resource
      )
    end
    let(:importer) do
      VmwareHypervisorImporter.new(
        compute_resource: compute_resource
      )
    end

    describe '#import!' do
      setup do
        cluster
      end

      test 'imports hypervisors' do
        importer.import!
        host = Host::Managed.joins(:vmware_hypervisor_facet).find_by(:name => 'host1.example.com')

        # Test host attributes are set correctly
        assert_equal 'example.com', host.domain.name
        assert_equal 'PowerEdge R730', host.model.name
        assert_equal '1.2.3.4', host.ip
        assert_nil host.ip6
        assert_equal organization, host.organization
        assert_equal tax_location, host.location

        # Test facet attributes are set correctly
        assert_equal cluster, host.vmware_hypervisor_facet.vmware_cluster
        assert_equal 20, host.vmware_hypervisor_facet.cpu_cores
        assert_equal 40, host.vmware_hypervisor_facet.cpu_threads
        assert_equal 2, host.vmware_hypervisor_facet.cpu_sockets
        assert_equal 824_597_241_856, host.vmware_hypervisor_facet.memory
        assert_equal '4c4c4544-0051-3610-8046-c4c44f584a32', host.vmware_hypervisor_facet.uuid
      end

      test 'updates host by katello name' do
        host = FactoryBot.create(:host,  organization: organization)
        host.update!(:name => "virt-who-host1.example.com-#{organization.id}")
        importer.import!
        assert_equal 'host1.example.com', host.reload.name
      end
    end
  end
end
