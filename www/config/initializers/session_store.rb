# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_www_session',
  :secret      => '8804a75ee1ae1c4bcf0975ab043339245682ccbbe9b1d3e6d8aeb6c237d6a91fd1e6eeccaeb5b5b7d8a82b4190a80fec25d15931a7fde83aa132c78a5c8b23ee'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
