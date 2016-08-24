Rails.application.routes.draw do
  resources :case_requests,
    only: [:new, :create],
    path_names: { new: '' }

  root 'start#new'
end
