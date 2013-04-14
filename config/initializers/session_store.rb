# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
#ActionController::Base.session = {
#  :key         => '_bq_session',
#  :secret      => '6340aa86376793ce58c43edcc950f63b841e93f03fc35f6511e8024d6176f08e764519b8eb8d8fddb2516bb952068c7b5cfe1c57c25f699c9fd8f9a47f820618'
#}

Rails.application.config.session_store :cookie_store, :key => "_bq_session"

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
