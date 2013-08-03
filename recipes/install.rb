## Cookbook Name:: deploy-drupal
## Recipe:: install
##


mysql_connection = "mysql --user='root' --host='localhost' --password='#{node['mysql']['server_root_password']}'"
db_user = "'#{node['deploy-drupal']['install']['db_user']}'@'localhost'"
db_pass = node['deploy-drupal']['install']['db_pass']
db_name = node['deploy-drupal']['install']['db_name']

web_app node['deploy-drupal']['project_name'] do
  template "web_app.conf.erb"
  port node['deploy-drupal']['apache_port']
  server_name node['deploy-drupal']['project_name']
  server_aliases [node['deploy-drupal']['project_name']]
  docroot node['deploy-drupal']['drupal_root']
  notifies :restart, "service[apache2]"
end

# install permission script
template "/usr/local/bin/drupal-perm" do
  source "drupal-perm.sh.erb"
  mode 0755
  owner "root"
  group "root"
  variables({
    :project_path =>  node['deploy-drupal']['project_root'],
    :site_path    =>  node['deploy-drupal']['drupal_root'],
    :writable_dirs=>  node['deploy-drupal']['writable_dirs'],
    :user         =>  node['apache']['user'],
    :group        =>  node['deploy-drupal']['dev_group']
  })
end
# install reset script
template "/usr/local/bin/drupal-reset" do
  source "drupal-reset.sh.erb"
  mode 0755
  owner "root"
  group "root"
  variables({
    :db_connection => mysql_connection,
    :db_user => db_user,
    :db_name => db_name,
    :drupal_root => node['deploy-drupal']['drupal_root']
  })
  action :create_if_missing
end

grant_sql = "GRANT ALL ON #{db_name}.* TO #{db_user} IDENTIFIED BY '#{db_pass}';"

bash "prepare-mysql" do
  code <<-EOH
    #{mysql_connection} -e "#{grant_sql}; FLUSH PRIVILEGES;"
    #{mysql_connection} -e "CREATE DATABASE IF NOT EXISTS #{db_name};"
  EOH
end

conf_dir = "#{node['deploy-drupal']['drupal_root']}/sites/default"
# the settings.local.php template requires that its directory be
# declared as a resource
directory conf_dir do
  recursive true
end

template "settings.local.php" do
  source "settings.local.php.erb"
  path "#{conf_dir}/settings.local.php"
  mode 0460
  owner node['apache']['user']
  group node['deploy-drupal']['dev_group']
  notifies :reload, "service[apache2]"
  variables({
    :db_user => node['deploy-drupal']['install']['db_user'],
    :db_pass => db_pass,
    :db_name => db_name
  })
end

append_code = 'include_once("settings.local.php");'
# copy contents of default.settings.php
# unset db crendential variables, and includes local.settings.php
bash "configure-settings.php" do
  cwd conf_dir
  code <<-EOH
    cat default.settings.php > settings.php; 
    echo '#{append_code}' >> settings.php;
  EOH
  not_if "test -f settings.php", :cwd => conf_dir
  notifies :reload, "service[apache2]"
end

# MySQL-specific query that returns the number of tables in the Drupal database
table_count_sql = "SELECT * FROM information_schema.tables WHERE \
                   table_type = 'BASE TABLE' AND table_schema = '#{db_name}';"

db_empty = "#{mysql_connection} -e \"#{table_count_sql}\" | wc -l | xargs test 0 -eq"

dump_file = node['deploy-drupal']['install']['sql_dump']

execute "populate-db" do
  # dump file path might be relative to project_root
  cwd node['deploy-drupal']['project_root']
  command "zless '#{dump_file}' | #{mysql_connection} --database=#{db_name};"
  only_if db_empty
  only_if "test -f '#{dump_file}'", :cwd => node['deploy-drupal']['project_root']
  notifies :run, "execute[post-install-script]", :immediately
end

# fixes sendmail error https://drupal.org/node/1826652#comment-6706102
drush = "php -d sendmail_path=/bin/true  /usr/share/php/drush/drush.php"

drush_install = "#{drush} site-install --debug -y\
  --account-name=#{node['deploy-drupal']['install']['admin_user']}\
  --account-pass=#{node['deploy-drupal']['install']['admin_pass']}\
  --site-name='#{node['deploy-drupal']['project_name']}'"
# drush si is invoked without --db-url since it is only needed for creating
# the schemas if the database remains empty after loading the sql dump, if any.
execute "drush-site-install" do
  cwd node['deploy-drupal']['drupal_root']
  command drush_install
  only_if db_empty
  notifies :run, "execute[post-install-script]"
end
# the following resource is executed on every provision
bash "finish-provision" do
  # post install script might be relative to project_root
  cwd node['deploy-drupal']['drupal_root']
  code <<-EOH
    drush cache-clear all
    bash drupal-perm
  EOH
end

script_file = node['deploy-drupal']['install']['script']
# the post install script is only executed if the Drupal database 
# is populated from scratch, either by drush site-install or from sql dump file
execute "post-install-script" do
  cwd node['deploy-drupal']['project_root']
  command "bash '#{script_file}'"
  only_if "test -f '#{script_file}'", :cwd => node['deploy-drupal']['project_root']
  action :nothing
end
