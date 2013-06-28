## Cookbook Name:: deploy-drupal
## Recipe:: default
##
#

include_recipe 'deploy-drupal::lamp_stack'
include_recipe 'deploy-drupal::pear_dependencies'


MYSQL_ROOT_PASS = node['mysql']['server_root_password']
MYSQL_DRUPAL_USER = node['deploy-drupal']['mysql_user']
MYSQL_DRUPAL_PASS = node['deploy-drupal']['mysql_pass']
DRUPAL_DB_NAME = node['deploy-drupal']['db_name']

# the format mysql -u <user> -p<password> ... causes errors when password is empty
# Note that the mysql url with an empty password (password=''), as used in drush site-install, does not cause an error

MYSQL_DRUPAL_CONNECTION =  "mysql  --user='#{MYSQL_DRUPAL_USER}'\
                                   --host='localhost'\
                                   --password='#{MYSQL_DRUPAL_PASS}'\
                                   --database='#{DRUPAL_DB_NAME}'"

MYSQL_ROOT_CONNECTION =    "mysql  --user='root'\
                                   --host='localhost'\
                                   --password='#{MYSQL_ROOT_PASS}'"

SQL_LOAD_FILE = node['deploy-drupal']['sql_load_file']
SQL_POST_LOAD_SCRIPT = node['deploy-drupal']['sql_post_load_script']

DRUPAL_ADMIN_PASS = node['deploy-drupal']['admin_pass']
DRUPAL_SITE_NAME = node['deploy-drupal']['site_name']
DRUPAL_TRUSTEES = node['deploy-drupal']['dev_group']

DRUPAL_SOURCE_PATH = node['deploy-drupal']['codebase_source_path']
DRUPAL_DEPLOY_DIR = node['deploy-drupal']['deploy_directory']

APACHE_PORT = node['deploy-drupal']['apache_port']
APACHE_USER = node['deploy-drupal']['apache_user']
APACHE_GROUP = node['deploy-drupal']['apache_group']

DESTROY_EXISTING = node['deploy-drupal']['destroy_existing']

directory DRUPAL_DEPLOY_DIR do
  owner APACHE_USER
  group APACHE_GROUP #specific to your usecase; perhaps should default to Vagrant
  recursive true
end

execute "validate-drush-works" do
  command "drush status"
  cwd DRUPAL_DEPLOY_DIR
end
# destroy contents of drupal root folder if DESTROY_EXISTING is set
# keeps a drush archive-dump in vagrant shared folder (/vagrant/ hardcoded)
bash "destroy-existing-site" do
  cwd DRUPAL_DEPLOY_DIR
  code <<-EOH
    cd #{DRUPAL_SITE_NAME}
    drush archive-dump --tar-options="--exclude=.git" --destination=/vagrant/drupal_archive_dump.tar
    drush sql-query "DROP DATABASE #{DRUPAL_DB_NAME};"
    rm -rf #{DRUPAL_DEPLOY_DIR}/*
  EOH
  only_if {DESTROY_EXISTING == "true"}
end

# Copies drupal codebase from DRUPAL_SOURCE_PATH to DRUPAL_DEPLOY_DIR
bash "copy-drupal-site" do 
  # see http://superuser.com/a/367303 for cp syntax discussion
  # assumes target directory already exists
  code <<-EOH
    cp -Rf #{DRUPAL_SOURCE_PATH}/. '#{DRUPAL_DEPLOY_DIR}'
  EOH
  # If identical, `creates "index.php"` will prevent resource execution.
  # This is great if you want to deploy directly to Vagrant shared folder
  creates "#{DRUPAL_DEPLOY_DIR}/index.php"
  notifies :restart, "service[apache2]", :delayed
  only_if "test -d '#{DRUPAL_SOURCE_PATH}' && test -f '#{DRUPAL_SOURCE_PATH}/index.php'"
end

bash "download-drupal" do
  # download Drupal if there is no index.php in the source path
  cwd "#{DRUPAL_DEPLOY_DIR}/.."

  code <<-EOH
    drush dl drupal-7 --destination=. --drupal-project-rename=site -y
  EOH
  creates "#{DRUPAL_DEPLOY_DIR}/index.php"
  notifies :restart, "service[apache2]", :delayed
  # not if there is already stuff copied over to deployment directory
  not_if "test -d '#{DRUPAL_DEPLOY_DIR}' && test -f '#{DRUPAL_DEPLOY_DIR}/index.php'"
end


web_app DRUPAL_SITE_NAME do
  template "web_app.conf.erb"
  port APACHE_PORT
  server_name DRUPAL_SITE_NAME
  server_aliases [DRUPAL_SITE_NAME]
  docroot DRUPAL_DEPLOY_DIR
  notifies :restart, "service[apache2]", :delayed
end

# Disable the default apache site (don't need it, and it conflicts with deploying on port 80)
# TODO: solve this more nicely
apache_site "000-default" do
  enable false
  notifies :restart, "service[apache2]", :delayed
end


#TODO Secure MySql database (tighten privileges and remove anonymous and @% users)
bash "add-mysql-user" do
  # is idempotent since "create user" and "grant all" are idempotent
  code <<-EOH
    #{MYSQL_ROOT_CONNECTION} -e "CREATE DATABASE IF NOT EXISTS #{DRUPAL_DB_NAME};"
    #{MYSQL_ROOT_CONNECTION} -e "GRANT ALL ON #{DRUPAL_DB_NAME}.* TO '#{MYSQL_DRUPAL_USER}'@'localhost' IDENTIFIED BY '#{MYSQL_DRUPAL_PASS}'; FLUSH PRIVILEGES;"
    #{MYSQL_DRUPAL_CONNECTION} -e "SHOW TABLES;"
  EOH
end

# load the drupal database from specified local SQL file
execute "load-drupal-db-from-sql" do
  cwd DRUPAL_DEPLOY_DIR 
  #TODO: not robust to errors connecting to DB
  mysql_empty_check_cmd = "drush sql-query 'show tables;' | wc -l | xargs test 0 -eq"

  # SQL_LOAD_FILE might be nil, must be quoted
  only_if "test -f '#{SQL_LOAD_FILE}'  && #{mysql_empty_check_cmd}", :cwd => DRUPAL_DEPLOY_DIR
  # Using zless instead of cat/zcat to optionally support gzipped files 
  # "`drush sql-connect`" because "drush sqlc" returns 0 even on connection failure
  command "zless '#{SQL_LOAD_FILE}' | `drush sql-connect`"
  notifies :run, "execute[drush cache-clear]"
end

execute "drush-site-install" do
  cwd DRUPAL_DEPLOY_DIR
  # fixes sendmail error https://drupal.org/node/1826652#comment-6706102
  command "php -d sendmail_path=/bin/true /usr/share/php/drush/drush.php site-install standard -y \
               --account-name=admin --account-pass=#{DRUPAL_ADMIN_PASS} \
               --db-url=mysql://#{MYSQL_DRUPAL_USER}:'#{MYSQL_DRUPAL_PASS}'@localhost/#{DRUPAL_DB_NAME} \
               --site-name='#{DRUPAL_SITE_NAME}' --clean-url=0"
  # requires drush 6
  only_if "drush status --fields=db-status | grep Connected | wc -l | xargs test 0 -eq", :cwd => DRUPAL_DEPLOY_DIR
  #notifies :run, "execute[drush-check-for-updates]"
  notifies :run, "execute[drush-suppress-http-status-error]"
end

execute "drush-suppress-http-status-error" do
  cwd DRUPAL_DEPLOY_DIR
  command "drush vset -y drupal_http_request_fails FALSE"
  action :nothing
end

# drush cache clear
execute "drush cache-clear" do
  cwd DRUPAL_DEPLOY_DIR 
  action :nothing
end

# run customized sql-post-load-script, if requested
execute "customized-sql-post-load-script" do
  command "bash '#{SQL_POST_LOAD_SCRIPT}'"
  cwd DRUPAL_DEPLOY_DIR 
  only_if "test -f '#{SQL_POST_LOAD_SCRIPT}'"
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
    :files_path => node['deploy-drupal']['files_path'],
    :user  => APACHE_USER,
    :group => DRUPAL_TRUSTEES 
  })
end

execute "fix-drupal-permissions" do
  cwd DRUPAL_DEPLOY_DIR
  Chef::Log.info(DRUPAL_DEPLOY_DIR)
  command "bash drupal-perm.sh"
end
