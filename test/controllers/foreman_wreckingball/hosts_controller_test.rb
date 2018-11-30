# frozen_string_literal: true

require 'test_plugin_helper'

module ForemanWreckingball
  class HostsControllerTest < ActionController::TestCase
    let(:fake_task) { OpenStruct.new(id: 123) }

    setup do
      Setting::Wreckingball.load_defaults
    end

    describe '#status_dashboard' do
      context 'when there are no hosts with wreckingball statuses' do
        test 'shows an empty status page' do
          get :status_dashboard, session: set_session_user
          assert_response :success
        end
      end

      context 'when there are hosts with wreckingball statuses' do
        setup do
          FactoryBot.create(:host, :with_wreckingball_statuses, owner: users(:admin))
          FactoryBot.create(:host, :with_wreckingball_statuses, owner: FactoryBot.create(:usergroup, users: [users(:admin)]))
          FactoryBot.create(:host, :with_wreckingball_statuses, owner: FactoryBot.create(:user))
          FactoryBot.create(:host, :with_wreckingball_statuses, owner: FactoryBot.create(:usergroup))
        end

        test 'shows a status page' do
          get :status_dashboard, session: set_session_user
          assert_response :success
        end

        test 'should show all hosts' do
          get :status_dashboard, session: set_session_user
          assert_equal 4, assigns[:data].first[:counter][:ok]
        end

        test 'should show only owned hosts' do
          get :status_dashboard, params: { owned_only: true }, session: set_session_user
          assert_equal 2, assigns[:data].first[:counter][:ok]
        end
      end
    end

    describe '#status_hosts' do
      test 'returns correct counts' do
        FactoryBot.create_list(:vmware_hardware_version_status, 3, :with_ok_status)
        FactoryBot.create_list(:vmware_hardware_version_status, 4, :with_out_of_date_status)

        get :status_hosts, params: { status: ::ForemanWreckingball::HardwareVersionStatus.host_association },
                           session: set_session_user, xhr: true

        assert_response :ok
        json = JSON.parse(response.body)
        assert_equal 4, json['recordsTotal']
        assert_equal 4, json['recordsFiltered']
        assert_equal 4, json['data'].size
      end

      test 'returns hosts for status' do
        ok_status = FactoryBot.create(:vmware_hardware_version_status, :with_ok_status)
        out_of_date_status = FactoryBot.create(:vmware_hardware_version_status, :with_out_of_date_status)

        get :status_hosts, params: { status: ::ForemanWreckingball::HardwareVersionStatus.host_association },
                           session: set_session_user, xhr: true

        assert_response :ok

        data = JSON.parse(response.body)['data']

        hosts_names = data.map { |host| host['name'] }
        assert_equal 1, data.size
        assert_includes hosts_names, out_of_date_status.host.name
        refute_includes hosts_names, ok_status.host.name
      end

      test 'returns hosts for spectre v2 status' do
        FactoryBot.create_list(:vmware_spectre_v2_status, 1, :with_enabled)
        FactoryBot.create_list(:vmware_spectre_v2_status, 2, :with_missing)

        get :status_hosts, params: { status: ::ForemanWreckingball::SpectreV2Status.host_association },
                           session: set_session_user, xhr: true

        data = JSON.parse(response.body)['data']
        assert_equal 2, data.size
      end

      describe 'filtering by owner' do
        setup do
          FactoryBot.create(:host, :with_wreckingball_statuses, owner: users(:admin))
          FactoryBot.create(:host, :with_wreckingball_statuses, owner: FactoryBot.create(:usergroup, users: [users(:admin)]))
          FactoryBot.create(:host, :with_wreckingball_statuses, owner: FactoryBot.create(:user))
          FactoryBot.create(:host, :with_wreckingball_statuses, owner: FactoryBot.create(:usergroup))
        end

        test 'should show all hosts' do
          get :status_hosts, params: { status: ::ForemanWreckingball::SpectreV2Status.host_association },
                             session: set_session_user, xhr: true
          assert_equal 4, JSON.parse(response.body)['data'].count
        end

        test 'should show only owned hosts' do
          get :status_hosts, params: { status: ::ForemanWreckingball::SpectreV2Status.host_association, owned_only: true },
                             session: set_session_user, xhr: true
          assert_equal 2, JSON.parse(response.body)['data'].count
        end
      end
    end

    describe '#refresh_status_dashboard' do
      test 'redirects to scheduled task' do
        FactoryBot.create(:some_task, :vmware_sync, :stopped)

        ForemanTasks.expects(:async_task).returns(fake_task)
        put :refresh_status_dashboard, session: set_session_user
        assert_response :redirect
        assert_includes flash[:success], 'successfully scheduled'
        assert_redirected_to foreman_tasks_task_path(123)
      end

      test 'show flash warning message when task is already running' do
        FactoryBot.create(:some_task, :vmware_sync, :running)

        put :refresh_status_dashboard, session: set_session_user
        assert_response :redirect
        assert_includes flash[:warning], 'task is already running'
        assert_redirected_to status_dashboard_hosts_path
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
