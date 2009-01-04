set :application, "mycitytrain"
set :repository,  "git://github.com/dogeth/test.git"

# If you aren't deploying to /u/apps/#{application} on the target
# servers (which is the default), you can specify the actual location
# via the :deploy_to variable:
# set :deploy_to, "/var/www/#{application}"
set :deploy_to, "/home/train/domains/mycitytrain.info/"

# If you aren't using Subversion to manage your source code, specify
# your SCM below:
# set :scm, :subversion
set :scm, :git

server "mycitytrain.info", :app, :web, :db, :primary => true

set :user, "train"
set :scm_username, "lachlan"
set :use_sudo, false
