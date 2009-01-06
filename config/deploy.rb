set :application, "mycitytrain"

#git
set :scm, :git
set :deploy_via, :remote_cache
set :repository,  "git://github.com/dogeth/mycitytrain.git"
set :deploy_to, "/home/train/site/"

#server
server "deploy.mycitytrain.info", :app, :web, :db, :primary => true
set :user, "train"
ssh_options[:port] = 3636
set :use_sudo, false



