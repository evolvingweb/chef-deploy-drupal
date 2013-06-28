## Cookbook Name:: deploy-drupal
## Recipe:: default
##
#

include_recipe 'deploy-drupal::lamp_stack'
include_recipe 'deploy-drupal::pear_dependencies'


DRUPAL_TRUSTEES     = node['deploy-drupal']['dev_group']

SOURCE_PROJECT_DIR  = node['deploy-drupal']['source_project_path']
SOURCE_SITE_DIR     = SOURCE_PROJECT_DIR + "/" +
                      node['deploy-drupal']['source_site_path']

SOURCE_DB_FILE      = SOURCE_PROJECT_DIR + "/" +
                      node['deploy-drupal']['sql_load_file']
SOURCE_SCRIPT_FILE  = SOURCE_PROJECT_DIR + "/" +
                      node['deploy-drupal']['post_script_file']


DRUPAL_SITE_NAME    = node['deploy-drupal']['site_name']
DEPLOY_PROJECT_DIR  = node['deploy-drupal']['deploy_base_path']+
                      "/#{DRUPAL_SITE_NAME}"
DEPLOY_SITE_DIR     = "#{DEPLOY_PROJECT_DIR}/site"
DEPLOY_FILES_DIR    = DEPLOY_SITE_DIR + "/" +
                      node['deploy-drupal']['site_files_path']
DEPLOY_SQL_LOAD_FILE= DEPLOY_PROJECT_DIR + "/" +
                      node['deploy-drupal']['sql_load_file']
DEPLOY_SCRIPT_FILE  = DEPLOY_PROJECT_DIR + "/" +
                      node['deploy-drupal']['post_script_file']

APACHE_PORT         = node['deploy-drupal']['apache_port']
APACHE_USER         = node['deploy-drupal']['apache_user']
APACHE_GROUP        = node['deploy-drupal']['apache_group']

DESTROY_EXISTING    = node['deploy-drupal']['destroy_existing']

DB_ROOT_PASS        = node['mysql']['server_root_password']
DRUPAL_DB_USER      = node['deploy-drupal']['mysql_user']
DRUPAL_DB_PASS      = node['deploy-drupal']['mysql_pass']
DRUPAL_DB_NAME      = node['deploy-drupal']['db_name']
DRUPAL_ADMIN_PASS   = node['deploy-drupal']['admin_pass']

# the format mysql -u <user> -p<password> ... causes errors when password is empty
# Note that the mysql url with an empty password (password=''), as used in drush site-install, does not cause an error
DB_DRUPAL_CONNECTION="mysql --user='#{DRUPAL_DB_USER}'\
                            --host='localhost'\
                            --password='#{DRUPAL_DB_PASS}'\
                            --database='#{DRUPAL_DB_NAME}'"
DB_ROOT_CONNECTION  ="mysql --user='root'\
                            --host='localhost'\
                            --password='#{DB_ROOT_PASS}'"

Chef::Log.info("source project path is #{SOURCE_PROJECT_DIR}")
Chef::Log.info("source site path is #{SOURCE_SITE_DIR}")
Chef::Log.info("source db file path is #{SOURCE_DB_FILE}")
Chef::Log.info("source post-install script path is #{SOURCE_SCRIPT_FILE}")
Chef::Log.info("deploy project path is #{DEPLOY_PROJECT_DIR}")
Chef::Log.info("deploy site path is #{DEPLOY_SITE_DIR}")
Chef::Log.info("deploy db dump path is #{DEPLOY_SQL_LOAD_FILE}")
Chef::Log.info("deploy post-install script path is #{DEPLOY_SCRIPT_FILE}")
Chef::Log.info("Drupal files path is #{DEPLOY_FILES_DIR}")



directory DEPLOY_PROJECT_DIR do
  owner DRUPAL_TRUSTEES
  group DRUPAL_TRUSTEES
  recursive true 
end

directory DEPLOY_SITE_DIR do
  owner APACHE_USER
  group DRUPAL_TRUSTEES 
  recursive true
end

execute "validate-drush-works" do
  command "drush status"
  cwd DEPLOY_SITE_DIR
end
# TODO decouple from Vagrant
# destroy contents of drupal root folder if DESTROY_EXISTING is set
# keeps a drush archive-dump in vagrant shared folder (/vagrant/ hardcoded)
bash "destroy-existing-site" do
  cwd DEPLOY_PROJECT_DIR
  code <<-EOH
    cd #{DEPLOY_SITE_DIR}
    drush archive-dump --tar-options="--exclude=.git" --destination=/vagrant/drupal_archive_dump.tar
    drush sql-query "DROP DATABASE #{DRUPAL_DB_NAME};"
    rm -rf #{DEPLOY_PROJECT_DIR}/*
  EOH
  only_if { DESTROY_EXISTING == "true" }
end

# Copies drupal codebase from DRUPAL_SOURCE_PATH to DRUPAL_DEPLOY_DIR
bash "copy-drupal-site" do 
  # see http://superuser.com/a/367303 for cp syntax discussion
  # assumes target directory already exists
  code <<-EOH
    cp -Rf  #{SOURCE_PROJECT_DIR}/.  '#{DEPLOY_PROJECT_DIR}/'
  EOH
  # If identical, `creates "index.php"` will prevent resource execution.
  # This is great if you want to deploy directly to Vagrant shared folder
  creates "#{DEPLOY_SITE_DIR}/index.php"
  notifies :restart, "service[apache2]", :delayed
  only_if(
    "test -d '#{SOURCE_SITE_DIR}' && \
     test -f '#{SOURCE_SITE_DIR}/index.php'"
  )
end

bash "download-drupal" do
  # download Drupal if there is no index.php in the source path
  cwd "#{DEPLOY_PROJECT_DIR}/.."

  code <<-EOH
    drush dl drupal-7 --destination=. --drupal-project-rename=site -y
  EOH
  creates "#{DEPLOY_SITE_DIR}/index.php"
  notifies :restart, "service[apache2]", :delayed
  # not if there is already stuff copied over to deployment directory
  not_if( 
    "test -d '#{DEPLOY_SITE_DIR}' && \
     test -f '#{DEPLOY_SITE_DIR}/index.php'"
  )
end

web_app DRUPAL_SITE_NAME do
  template "web_app.conf.erb"
  port APACHE_PORT
  server_name DRUPAL_SITE_NAME
  server_aliases [DRUPAL_SITE_NAME]
  docroot DEPLOY_SITE_DIR
  notifies :restart, "service[apache2]", :delayed
end

# Disable the default apache site (don't need it, and it conflicts with deploying on port 80)
# TODO: solve this more nicely
apache_site "000-default" do
  enable false
  notifies :restart, "service[apache2]", :delayed
end


#TODO Secure MySql database (tighten privileges and 
# remove anonymous and @ % users)
bash "add-mysql-user" do
  code <<-EOH
    #{DB_ROOT_CONNECTION} -e "CREATE DATABASE IF NOT EXISTS #{DRUPAL_DB_NAME};"
    #{DB_ROOT_CONNECTION} -e "GRANT ALL ON #{DRUPAL_DB_NAME}.* TO
    '#{DRUPAL_DB_USER}'@'localhost' IDENTIFIED BY '#{DRUPAL_DB_PASS}'; FLUSH PRIVILEGES;"
    #{DB_DRUPAL_CONNECTION} -e "SHOW TABLES;"
  EOH
end

# load the drupal database from specified local SQL file
execute "load-drupal-db-from-sql" do
  cwd DEPLOY_SITE_DIR
  
  #TODO: not robust to errors connecting to DB
  mysql_empty_check_cmd = "drush sql-query 'show tables;' | wc -l | xargs test 0 -eq"

  # SQL_LOAD_FILE might be nil, must be quoted
  only_if  "test -f '#{DEPLOY_SQL_LOAD_FILE}' && #{mysql_empty_check_cmd}"
  
  # Using zless instead of cat/zcat to optionally support gzipped files 
  # "`drush sql-connect`" because "drush sqlc" returns 0 even on connection failure
  command "zless '#{DEPLOY_SQL_LOAD_FILE}' | `drush sql-connect`"
  notifies :run, "execute[drush cache-clear]"
end

execute "drush-site-install" do
  cwd DEPLOY_SITE_DIR
  
  # fixes sendmail error https://drupal.org/node/1826652#comment-6706102
  command "php -d sendmail_path=/bin/true /usr/share/php/drush/drush.php \
                site-install standard -y \
                --account-name=admin --account-pass=#{DRUPAL_ADMIN_PASS} \
                --db-url=mysql://#{DRUPAL_DB_USER}:'#{DRUPAL_DB_PASS}'@localhost/#{DRUPAL_DB_NAME} \
                --site-name='#{DRUPAL_SITE_NAME}' 
                --clean-url=0"
  
  # requires drush 6
  only_if "drush status --fields=db-status | grep Connected | wc -l | xargs test 0 -eq", :cwd => DEPLOY_SITE_DIR
  notifies :run, "execute[drush-suppress-http-status-error]"
end

execute "drush-suppress-http-status-error" do
  cwd DEPLOY_SITE_DIR
  command "drush vset -y drupal_http_request_fails FALSE"
  action :nothing
end

# drush cache clear
execute "drush cache-clear" do
  cwd DEPLOY_SITE_DIR 
  action :nothing
end

# run customized sql-post-load-script, if requested
execute "customized-sql-post-load-script" do
  command "bash '#{DEPLOY_SCRIPT_FILE}'"
  cwd DEPLOY_SITE_DIR
  only_if "test -f '#{DEPLOY_SCRIPT_FILE}'"
  action :nothing
  subscribes :run, "execute[load-drupal-db-from-sql]"
end

# the group has full access over drupal root folder, should not include www-data
group DRUPAL_TRUSTEES do
  append true
end

template "/usr/local/bin/drupal-perm.sh" do
  source "drupal-perm.sh.erb"
  mode 0750
  owner "root"
  group "root"
  variables({
    :files_path => DEPLOY_FILES_DIR, 
    :user  => APACHE_USER,
    :group => DRUPAL_TRUSTEES 
  })
end

execute "fix-drupal-permissions" do
  cwd DEPLOY_SITE_DIR
  command "bash drupal-perm.sh"
end
