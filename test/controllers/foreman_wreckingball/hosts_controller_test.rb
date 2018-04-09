require 'test_plugin_helper'

module ForemanWreckingball
  class HostsControllerTest < ActionController::TestCase
    let(:task_id) { 123 }
    let(:fake_task) do
      OpenStruct.new(
        id: task_id
      )
    end

    describe '#status_dashboard' do
      test 'shows an empty status page' do
        get :status_dashboard, {}, set_session_user
        assert_response :success
      end

      test 'shows a status page' do
        FactoryGirl.create_list(:host, 5, :with_wreckingball_statuses)
        get :status_dashboard, {}, set_session_user
        assert_response :success
      end
    end

    describe '#refresh_status_dashboard' do
      test 'redirects to scheduled task' do
        ForemanTasks.expects(:async_task).returns(fake_task)
        put :refresh_status_dashboard, {}, set_session_user
        assert_response :redirect
        assert_includes flash[:success], 'successfully scheduled'
        assert_redirected_to foreman_tasks_task_path(123)
      end
    end

    describe '#remediate' do
      let(:host) do
        FactoryGirl.create(:host, :with_wreckingball_statuses)
      end

      test 'redirects to scheduled task' do
        ForemanTasks.expects(:async_task).returns(fake_task)
        put :remediate, { status_id: host.vmware_operatingsystem_status_object.id, id: host.id }, set_session_user
        assert_response :redirect
        assert_includes flash[:success], 'successfully scheduled'
        assert_redirected_to foreman_tasks_task_path(123)
      end

      test 'raises error when status can not be remediated' do
        FactoryGirl.create(:host, :with_wreckingball_statuses)
        assert_raises Foreman::Exception do
          put :remediate, { status_id: host.vmware_tools_status_object.id, id: host.id }, set_session_user
        end
      end

      test 'returns not found when host id is invalid' do
        put :remediate, { status_id: nil, id: 'invalid' }, set_session_user
        assert_response :not_found
      end

      test 'returns not found when status id is invalid' do
        FactoryGirl.create(:host, :with_wreckingball_statuses)
        put :remediate, { status_id: 'invalid', id: host.id }, set_session_user
        assert_response :not_found
      end
    end
  end
end
