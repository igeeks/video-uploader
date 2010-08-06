# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_zencoder_session',
  :secret      => '09c9306f2b5aef1420e9bd22de4a0f2768b53f8b1caee77f06481a5f8cc78d34eb49ac0bb6c5460afc02af8a0c8be16ab841d15606afb80908515b7eeaa2197d'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store

ActionController::Dispatcher.middleware.insert_before(
  ActionController::Session::CookieStore, 
  FlashSessionCookieMiddleware, 
  ActionController::Base.session_options[:key]
)
