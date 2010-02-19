set :application, "mycitytrain"

#git
set :scm, :git
set :branch, "master"
set :deploy_via, :remote_cache
set :repository,  "git@github.com:dogeth/mct.git"
set :deploy_to, "/home/train/site/"

#server
server "ssh.mycitytrain.info", :app, :web, :db, :primary => true
set :user, "train"
ssh_options[:port] = 3636
set :use_sudo, false
default_run_options[:pty] = true 
 
namespace :deploy do
  
  desc <<-DESC
    [internal] Updates the symlink for database.yml file to the just deployed release.
  DESC
  task :symlink, :except => { :no_release => true } do
    run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
  end
  after "deploy:update_code", "deploy:symlink"
  
   #See http://www.simonecarletti.com/blog/2008/12/capistrano-deploy-recipe-with-passenger-mod_rails-taste/
   desc <<-DESC
     Restarts your application. \
     This works by creating an empty `restart.txt` file in the `tmp` folder
     as requested by Passenger server.
   DESC
   task :restart, :roles => :app, :except => { :no_release => true } do
     run "touch #{current_path}/tmp/restart.txt"
   end
end