if Rails::VERSION::STRING < "4" # Rails2 routing starts here
# ==============================================================================
# RAILS 2 routing starts here
# ==============================================================================
ActionController::Routing::Routes.draw do |map|
  map.resources :cronjob_modes

  map.resources :task_groups

  map.resources :readonly_tasks

  map.resources :allowed_statuses

  map.resources :workflows

  map.resources :manual_log_entries

  map.resources :sandboxes
  map.resources :jira_bugs
  map.resources :changelogs
  map.resources :components
  map.resources :package_relationships
  map.resources :relationships
  map.resources :settings
  map.resources :p_attachments
  map.resources :tasks, :has_many => [:packages, :statuses, :tags, :settings]
  map.resources :brew_tags, :has_many => [:packages]
  map.resources :tags
  map.resources :statuses, :has_many => :packages
  map.resources :packages
  map.resources :sessions
  map.resources :users, :has_many => [:packages, :user_views]
  map.resources :user_views
  map.resources :import
  map.resources :comments
  map.resources :bz_bugs
  map.logout '/logout', :controller => 'sessions', :action => 'destroy'
  map.login '/login', :controller => 'sessions', :action => 'new'
  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'tasks/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'tasks/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :tasks

  # Sample resource route with options:
  #   map.resources :tasks, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resourc  e route with sub-resources:
  #   map.resources :tasks, :has_many => [ :comments, :sales ], :has_one => :seller

  # Sample resource route with more complex sub-resources
  #   map.resources :tasks do |tasks|
  #     tasks.resources :comments
  #     tasks.resources :sales, :collection => { :recent => :get }
  #   end

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/tasks/* to Admin::tasksController (app/controllers/admin/tasks_controller.rb)
  #     admin.resources :tasks
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  # map.root :controller => "welcome"

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  # Note: These default routes make all actions in every controller accessible via GET requests. You should
  # consider removing or commenting them out if you're using named routes and resources.
  map.connect 'errata_check/sync', :controller => 'errata_check', :action => 'sync'
  map.connect 'errata_check/sync_bz', :controller => 'errata_check', :action => 'sync_bz'
  map.connect 'errata_check/sync_rpmdiffs', :controller => 'errata_check', :action => 'sync_rpmdiffs'
  map.connect 'cronjob/products_to_build', :controller => 'cronjob_modes', :action => 'products_to_build'
  map.connect 'mass-rebuild/first-step', :controller => 'mass_rebuild', :action => 'first_step'
  map.connect 'mass-rebuild/second-step', :controller => 'mass_rebuild', :action => 'second_step'
  map.connect 'mass-rebuild/third-step', :controller => 'mass_rebuild', :action => 'third_step'
  map.connect 'mass-rebuild/fourth-step', :controller => 'mass_rebuild', :action => 'fourth_step'
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
else # Rails 4 routing starts here
# ==============================================================================
# RAILS 4 routing starts here
# ==============================================================================
Rails.application.routes.draw do
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  resources :cronjob_modes
  resources :task_groups
  resources :readonly_tasks
  resources :allowed_statuses
  resources :workflows
  resources :manual_log_entries
  resources :sandboxes
  resources :jira_bugs
  resources :changelogs
  resources :components
  resources :package_relationships
  resources :relationships
  resources :settings
  resources :p_attachments

  resources :tasks do
    resources :packages, :statuses, :tags, :settings
  end

  resources :brew_tags do
    resources :packages
  end
  resources :tags

  resources :statuses do
    resources :packages
  end

  resources :sessions

  resources :users do
   resources :packages, :user_views
  end
  
  resources :user_views
  resources :import
  resources :comments
  resources :bz_bugs
  
  # ============================================================================
  # TODO: verify that those changes are valid
  # ============================================================================
  # Use Ruby 1.8.7 notations for compatibility reasons
  # Safe to change it after migration
  get 'logout' => 'sessions#destroy', :as => 'logout'
  get 'login' => 'sessions#new', :as => 'login'
  post 'login' => 'sessions#create'

  get 'errata_check/sync' => 'errata_check#sync'
  get 'errata_check/sync_bz' => 'errata_check#sync_bz'
  get 'errata_check/sync_rpmdiffs' => 'errata_check#sync_rpmdiffs'
  get 'cronjob/products_to_build' => 'cronjob_modes#products_to_build'
  get 'mass-rebuild/first-step' => 'mass_rebuild#first_step'
  get 'mass-rebuild/second-step' => 'mass_rebuild#second_step'
  get 'mass-rebuild/third-step' => 'mass_rebuild#third_step'
  get 'mass-rebuild/fourth-step' => 'mass_rebuild#fourth_step'
  match ':controller(/:action(/:id))(.:format)', :via => [:get, :post, :put, :destroy]
end
end
