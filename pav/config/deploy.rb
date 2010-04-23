#========================
#CONFIG
#========================
require "/Users/simonnielsen/Documents/Code/diglabs/pav/config/capistrano_database"
set :application, "pav"
set :scm, :git
set :git_enable_submodules, 1
set :repository,  "git@github.com:simonhn/diglabs.git"
set :branch, "master"
set :ssh_options, { :forward_agent => true }
set :stage, :production
set :user, "simonhn"
set :runner, "deploy"
set :deploy_to, "/var/www/vhosts/com.simonium.api/#{application}"
set :deploy_via, :remote_cache
set :keep_releases, 2
set :app_server, :passenger
set :domain, "simonium.com"
#========================
#ROLES
#========================
role :app, domain
role :web, domain
role :db, domain, :primary => true
#========================
#CUSTOM
#========================
namespace :deploy do
  
  # This will make sure that Capistrano doesn't try to run rake:migrate (this is not a Rails project!)
  task :cold do
    deploy.update
  end
end