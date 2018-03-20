Rails.application.routes.draw do
  scope '/wreckingball' do
    constraints(:id => /[^\/]+/) do
      resources :hosts, controller: 'foreman_wreckingball/hosts', :only => [] do
        member do
          put :remediate
        end
        collection do
          get :status_dashboard
          put :refresh_status_dashboard
        end
      end
    end
  end
end
