# Be sure to restart your server when you modify this file.

MyCitytrain::Application.config.session_store :cookie_store, :key => '_mycitytrain_session', :expire_after => 25.years, :secret => '296835085ba78206ede6b257f50912e06955d99069da769078803d0245734e5b02dc3b43efb4b63dddcfd7accc8ce4cdcacbaeeb347c969be84a50f2dd673e08'

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# MyCitytrain::Application.config.session_store :active_record_store
