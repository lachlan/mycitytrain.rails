require 'deploy/passenger'

set :application, "mycitytrain"

#git
set :scm, :git
set :deploy_via, :remote_cache
set :repository,  "git://github.com/dogeth/mycitytrain.git"
set :deploy_to, "/home/train/site/"

#server
server "ssh.mycitytrain.info", :app, :web, :db, :primary => true
set :user, "train"
ssh_options[:port] = 3636
set :use_sudo, false

namespace :deploy do
  #See http://toolmantim.com/articles/setting_up_capistrano_on_segpub  
   desc "Link in the production database.yml"
   task :after_update_code do
     run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
   end
end