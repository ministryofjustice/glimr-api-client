Rails.application.routes.draw do
  resources :case_requests,
    only: [:new, :create],
    path_names: { new: '' }

  resources :fees,
    only: [:new, :create]

  root 'start#new'
end
