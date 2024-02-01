# frozen_string_literal: true

require 'test_plugin_helper'

class ComputeResourcesControllerTest < ActionController::TestCase
  describe '#show' do
    let(:compute_resource) { FactoryBot.create(:compute_resource, :vmware) }
    let(:vmware_cluster) { FactoryBot.create(:vmware_cluster, compute_resource: compute_resource) }

    test 'shows a compute resource with hypervisors' do
      skip if Gem::Version.new(Foreman::Version.new.to_s) < Gem::Version.new('1.19.0')
      FactoryBot.create_list(:vmware_hypervisor_facet, 5, vmware_cluster: vmware_cluster)

      get :show, params: { id: compute_resource.to_param }, session: set_session_user
      assert_response :success
      assert_includes @response.body, 'Hypervisors'
    end
  end
end
