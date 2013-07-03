## Cookbook Name:: deploy-drupal
## Recipe:: default
##
#

include_recipe 'deploy-drupal::lamp_stack'
include_recipe 'deploy-drupal::pear_dependencies'

# the shorthand format mysql -u <user> -p<password> ... causes errors when
# password is empty. 
DB_DRUPAL_CONNECTION= "mysql  --user='#{node['deploy-drupal']['mysql_user']}'\
                              --host='localhost'\
                              --password='#{node['deploy-drupal']['mysql_pass']}'\
                              --database='#{node['deploy-drupal']['db_name']}'"

DB_ROOT_CONNECTION  = "mysql  --user='root'\
                              --host='localhost'\
                              --password='#{node['mysql']['server_root_password']}'"

DRUSH_DB_URL        = "mysql://" +
                          node['deploy-drupal']['mysql_user'] + ":'" +
                          node['deploy-drupal']['mysql_pass'] + "'@localhost/" +
                          node['deploy-drupal']['db_name']

DRUSH_STATUS_CMD    = "drush status --fields=db-status \
                      | grep Connected | wc -l | xargs test 0 -eq"
# Convert all paths to absolute equivalents
SOURCE_SITE_DIR     = node['deploy-drupal']['source_project_path'] + "/" +
                      node['deploy-drupal']['site_path']

DEPLOY_PROJECT_DIR  = node['deploy-drupal']['deploy_base_path']+
                      "/#{node['deploy-drupal']['site_name']}"

DEPLOY_SITE_DIR     = DEPLOY_PROJECT_DIR + "/" + node['deploy-drupal']['site_path']

DEPLOY_FILES_DIR    = DEPLOY_SITE_DIR + "/" +
                      node['deploy-drupal']['site_files_path']

DEPLOY_SQL_LOAD_FILE= DEPLOY_PROJECT_DIR + "/" +
                      node['deploy-drupal']['sql_load_file']

DEPLOY_SCRIPT_FILE  = DEPLOY_PROJECT_DIR + "/" +
                      node['deploy-drupal']['post_script_file']

directory DEPLOY_SITE_DIR do
  owner node['deploy-drupal']['apache_user']
  group node['deploy-drupal']['dev_group_name']
  recursive true
end

execute "validate-drush-works" do
  command "drush status"
  cwd node['deploy-drupal']['deploy_site_dir']
end

# destroy the project root directory and removes the Drupal database user 
# if reset attribue is set to "true".
# keeps a drush archive-dump in drush's default directory (~/drush-backups/)
bash "reset-project" do
  code <<-EOH
    cd #{DEPLOY_SITE_DIR}
    drush archive-dump --tar-options="--exclude=.git"
    drush sql-query "DROP DATABASE #{node['deploy-drupal']['db_name']};"
    #{DB_ROOT_CONNECTION} -e "DROP DATABASE #{node['deploy-drupal']['db_name']};"
    #{DB_ROOT_CONNECTION} -e "REVOKE ALL FROM #{node['deploy-drupal']['mysql_user']};"
    #{DB_ROOT_CONNECTION} -e "DROP USER '#{node['deploy-drupal']['mysql_user']}'@'localhost';"
    rm -rf #{DEPLOY_PROJECT_DIR}/*
  EOH
  only_if { node['deploy-drupal']['reset'] == "true" }
end

# copies the entire source_project_path directory to deployment root
bash "copy-drupal-site" do 
  # see http://superuser.com/a/367303 for cp syntax discussion
  # assumes target directory already exists
  code <<-EOH
    cp -Rf #{node['deploy-drupal']['source_project_path']}/. '#{DEPLOY_PROJECT_DIR}'
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
  cwd DEPLOY_PROJECT_DIR

  code <<-EOH
    drush dl drupal-7 --destination=. --drupal-project-rename=#{node['deploy-drupal']['site_path']} -y
  EOH
  creates "#{DEPLOY_SITE_DIR}/index.php"
  notifies :restart, "service[apache2]", :delayed
  # not if there is already stuff copied over to deployment directory
  not_if( 
    "test -d '#{DEPLOY_SITE_DIR}' && \
     test -f '#{DEPLOY_SITE_DIR}/index.php'"
  )
end

web_app node['deploy-drupal']['site_name'] do
  template "web_app.conf.erb"
  port node['deploy-drupal']['apache_port']
  server_name node['deploy-drupal']['site_name']
  server_aliases [node['deploy-drupal']['site_name']]
  docroot DEPLOY_SITE_DIR
  notifies :restart, "service[apache2]", :delayed
end

# Disable the default apache site (don't need it, and it conflicts with deploying on port 80)
# TODO: solve this more nicely
apache_site "000-default" do
  enable false
  notifies :restart, "service[apache2]", :delayed
end

execute "secure-initial-mysql-accounts" do
  command "#{DB_ROOT_CONNECTION} -e \"UPDATE mysql.user SET password= \
            PASSWORD('#{node['deploy-drupal']['mysql_unsafe_user_pass']}') \
            WHERE password='';\""
end

bash "add-mysql-user" do
  code <<-EOH
    #{DB_ROOT_CONNECTION} -e "CREATE DATABASE IF NOT EXISTS #{node['deploy-drupal']['db_name']};"
    #{DB_ROOT_CONNECTION} -e "GRANT ALL ON #{node['deploy-drupal']['db_name']}.* TO '#{node['deploy-drupal']['mysql_user']}'@'localhost' IDENTIFIED BY '#{node['deploy-drupal']['mysql_pass']}'; FLUSH PRIVILEGES;"
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
  cwd node['deploy-drupal']['deploy_site_dir'] 
  # fixes sendmail error https://drupal.org/node/1826652#comment-6706102
  command "php -d sendmail_path=/bin/true /usr/share/php/drush/drush.php \
                site-install standard -y \
                --account-name=#{node['deploy-drupal']['admin_user']} \
                --account-pass=#{node['deploy-drupal']['admin_pass']} \
                --db-url=#{DRUSH_DB_URL}\
                --site-name='#{node['deploy-drupal']['site_name']}'"
 
  # requires drush 6
  only_if DRUSH_STATUS_CMD, :cwd => DEPLOY_SITE_DIR
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
  cwd node['deploy-drupal']['deploy_site_dir']
  only_if "test -f '#{DEPLOY_SCRIPT_FILE}'"
  action :nothing
  subscribes :run, "execute[load-drupal-db-from-sql]"
end

template "/usr/local/bin/drupal-perm.sh" do
  source "drupal-perm.sh.erb"
  mode 0755
  owner "root"
  group "root"
  variables({
    :files_path => DEPLOY_FILES_DIR, 
    :user  => node['deploy-drupal']['apache_user'],
    :group => node['deploy-drupal']['dev_group_name'] 
  })
end

execute "fix-drupal-permissions" do
  cwd DEPLOY_PROJECT_DIR
  command "bash drupal-perm.sh"
end
