# frozen_string_literal: true

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
        get :status_dashboard, session: set_session_user
        assert_response :success
      end

      test 'shows a status page' do
        FactoryBot.create_list(:host, 5, :with_wreckingball_statuses)
        get :status_dashboard, session: set_session_user
        assert_response :success
      end
    end

    describe '#refresh_status_dashboard' do
      test 'redirects to scheduled task' do
        ForemanTasks.expects(:async_task).returns(fake_task)
        put :refresh_status_dashboard, session: set_session_user
        assert_response :redirect
        assert_includes flash[:success], 'successfully scheduled'
        assert_redirected_to foreman_tasks_task_path(123)
      end
    end

    describe '#schedule_remediate' do
      let(:host) do
        FactoryBot.create(:host, :with_wreckingball_statuses)
      end

      test 'shows a remediation schedule page' do
        get :schedule_remediate, params: { status_id: host.vmware_operatingsystem_status_object.id, id: host.id }, session: set_session_user
        assert_response :success
      end

      test 'returns not found when host id is invalid' do
        get :schedule_remediate, params: { status_id: nil, id: 'invalid' }, session: set_session_user
        assert_response :not_found
      end

      test 'returns not found when status id is invalid' do
        FactoryBot.create(:host, :with_wreckingball_statuses)
        get :schedule_remediate, params: { status_id: 'invalid', id: host.id }, session: set_session_user
        assert_response :not_found
      end
    end

    describe '#submit_remediate' do
      let(:host) do
        FactoryBot.create(:host, :with_wreckingball_statuses)
      end

      test 'redirects to scheduled task' do
        ForemanTasks.expects(:async_task).returns(fake_task)
        post :submit_remediate, params: { status_id: host.vmware_operatingsystem_status_object.id, id: host.id }, session: set_session_user
        assert_response :redirect
        assert_includes flash[:success], 'successfully scheduled'
        assert_redirected_to foreman_tasks_task_path(123)
      end

      test 'raises error when status can not be remediated' do
        FactoryBot.create(:host, :with_wreckingball_statuses)
        assert_raises Foreman::Exception do
          post :submit_remediate, params: { status_id: host.vmware_tools_status_object.id, id: host.id }, session: set_session_user
        end
      end

      test 'returns not found when host id is invalid' do
        post :submit_remediate, params: { status_id: nil, id: 'invalid' }, session: set_session_user
        assert_response :not_found
      end

      test 'returns not found when status id is invalid' do
        FactoryBot.create(:host, :with_wreckingball_statuses)
        post :submit_remediate, params: { status_id: 'invalid', id: host.id }, session: set_session_user
        assert_response :not_found
      end
    end
  end
end
