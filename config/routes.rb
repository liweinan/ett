ActionController::Routing::Routes.draw do |map|
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
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
