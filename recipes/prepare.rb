## Cookbook Name:: deploy-drupal
## Recipe:: prepare
##

# assemble all necessary query strings and paths
DRUSH_DB_URL        = "mysql://" +
                          node['deploy-drupal']['mysql_user'] + ":'" +
                          node['deploy-drupal']['mysql_pass'] + "'@localhost/" +
                          node['deploy-drupal']['db_name']

DRUSH_STATUS_CMD    = "drush status --fields=db-status \
                      | grep Connected | wc -l | xargs test 0 -eq"

DB_DRUPAL_CONNECTION= "mysql  --user='#{node['deploy-drupal']['mysql_user']}'\
                              --host='localhost'\
                              --password='#{node['deploy-drupal']['mysql_pass']}'\
                              --database='#{node['deploy-drupal']['db_name']}'"

DB_ROOT_CONNECTION  = "mysql  --user='root'\
                              --host='localhost'\
                              --password='#{node['mysql']['server_root_password']}'"
DEPLOY_PROJECT_DIR  = node['deploy-drupal']['deploy_base_path']+
                      "/#{node['deploy-drupal']['site_name']}"

DEPLOY_SITE_DIR     = DEPLOY_PROJECT_DIR + "/" + node['deploy-drupal']['site_path']

# setup system for site installation:
# directory, validate drush, web_app, mysql user
directory DEPLOY_SITE_DIR do
  owner node['deploy-drupal']['apache_user']
  group node['deploy-drupal']['dev_group_name']
  recursive true
end

execute "validate-drush-works" do
  command "drush status"
  cwd DEPLOY_SITE_DIR 
end

web_app node['deploy-drupal']['site_name'] do
  template "web_app.conf.erb"
  port node['deploy-drupal']['apache_port']
  server_name node['deploy-drupal']['site_name']
  server_aliases [node['deploy-drupal']['site_name']]
  docroot DEPLOY_SITE_DIR
  notifies :restart, "service[apache2]", :delayed
end

# Disable the default apache site 
# (don't need it, and it conflicts with deploying on port 80)
# TODO: solve this more nicely
apache_site "000-default" do
  enable false
  notifies :restart, "service[apache2]", :delayed
end

bash "add-mysql-user" do
  code <<-EOH
    #{DB_ROOT_CONNECTION} -e "CREATE DATABASE IF NOT EXISTS #{node['deploy-drupal']['db_name']};"
    #{DB_ROOT_CONNECTION} -e "GRANT ALL ON #{node['deploy-drupal']['db_name']}.* TO '#{node['deploy-drupal']['mysql_user']}'@'localhost' IDENTIFIED BY '#{node['deploy-drupal']['mysql_pass']}'; FLUSH PRIVILEGES;"
    #{DB_DRUPAL_CONNECTION} -e "SHOW TABLES;"
  EOH
end
