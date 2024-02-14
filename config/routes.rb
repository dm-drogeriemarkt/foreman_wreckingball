# frozen_string_literal: true

Rails.application.routes.draw do
  scope '/wreckingball' do
    constraints(id: %r{[^/]+}) do
      resources :hosts, controller: 'foreman_wreckingball/hosts', only: [] do
        collection do
          get :status_dashboard
          get :status_managed_hosts_dashboard
          get 'status_dashboard/hosts(/:status)', as: :ajax_status_dashboard, action: :status_hosts,
defaults: { format: :json }
          put :refresh_status_dashboard
          get :schedule_remediate
          post :submit_remediate
        end
      end
    end
  end
end
