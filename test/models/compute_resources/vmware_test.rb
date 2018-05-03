# frozen_string_literal: true

require 'test_plugin_helper'

class VmwareTest < ActiveSupport::TestCase
  setup { Fog.mock! }
  teardown { Fog.unmock! }
  let(:compute_resource) { FactoryBot.build(:vmware_cr, :uuid => 'Solutions') }

  test '#hypervisors returns hosts by cluster' do
    hosts = compute_resource.hypervisors(cluster_id: 'Solutionscluster').map(&:name)
    assert_includes hosts, 'host1.example.com'
  end
end
