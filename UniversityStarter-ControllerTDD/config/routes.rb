Rails.application.routes.draw do

   # create routes for department CRUD operations
  resources :departments, except: [:create, :update, :destroy]

  # set the default route to departments#index
  root 'departments#index'
end
