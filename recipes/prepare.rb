## Cookbook Name:: deploy-drupal
## Recipe:: prepare
##
## prepare the machine for drupal installation:
## configure apache vhost, install utility scripts,
## if necessary, create Drupal MySQL user
## if necessary, create Drupal database

# assemble all necessary query strings and paths
DB_ROOT_CONNECTION  = [ "mysql",
                        "--user='root'",
                        "--host='localhost'",
                        "--password='#{node['mysql']['server_root_password']}'"
                      ].join(' ')

MYSQL_GRANT_QUERY   = [ "GRANT ALL ON",
                        "#{node['deploy-drupal']['db_name']}.* TO",
                        "'#{node['deploy-drupal']['mysql_user']}'@'localhost'",
                        "IDENTIFIED BY '#{node['deploy-drupal']['mysql_pass']}';",
                        "FLUSH PRIVILEGES;"
                      ].join(' ') 

DEPLOY_PROJECT_DIR  = node['deploy-drupal']['deploy_dir']   + "/" +
                      node['deploy-drupal']['project_name']

DEPLOY_SITE_DIR     = DEPLOY_PROJECT_DIR   + "/" +
                      node['deploy-drupal']['drupal_root_dir']

# setup system for site installation:
# directory, validate drush, web_app, mysql user
web_app node['deploy-drupal']['project_name'] do
  template "web_app.conf.erb"
  port node['deploy-drupal']['apache_port']
  server_name node['deploy-drupal']['project_name']
  server_aliases [node['deploy-drupal']['project_name']]
  docroot "'#{DEPLOY_SITE_DIR}'"
  notifies :restart, "service[apache2]", :delayed
end

bash "prepare-mysql" do
  code <<-EOH
    #{DB_ROOT_CONNECTION} -e "#{MYSQL_GRANT_QUERY}"
    #{DB_ROOT_CONNECTION} -e "CREATE DATABASE IF NOT EXISTS #{node['deploy-drupal']['db_name']};"
  EOH
end

# install the permissions script
template "/usr/local/bin/drupal-perm" do
  source "drupal-perm.sh.erb"
  mode 0755
  owner "root"
  group "root"
  variables({
    :project_path =>  DEPLOY_PROJECT_DIR,
    :site_path    =>  DEPLOY_SITE_DIR,
    :files_path   =>  DEPLOY_SITE_DIR + "/" +
                      node['deploy-drupal']['drupal_files_dir'],
    :user         =>  node['apache']['user'],
    :group        =>  node['deploy-drupal']['dev_group_name'] 
  })
end

# install the reset script
template "/usr/local/bin/drupal-reset" do
  source "drupal-reset.sh.erb"
  mode 0755
  owner "root"
  group "root"
  variables({
    :site_path => "'#{DEPLOY_SITE_DIR}'",
    :deploy_path => "'#{node['deploy-drupal']['deploy_dir']}'",
    :db_connection => DB_ROOT_CONNECTION,
    :user => "'#{node['deploy-drupal']['mysql_user']}'@'localhost'",
    :db => node['deploy-drupal']['db_name']
  })
end
