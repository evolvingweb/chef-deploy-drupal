## Cookbook Name:: deploy-drupal
## Recipe:: install
##
web_app node['deploy-drupal']['project_name'] do
  template "web_app.conf.erb"
  port node['deploy-drupal']['apache_port']
  server_name node['deploy-drupal']['project_name']
  server_aliases [node['deploy-drupal']['project_name']]
  docroot node['deploy-drupal']['site_root']
  notifies :restart, "service[apache2]"
end

# install the permissions script
template "/usr/local/bin/drupal-perm" do
  source "drupal-perm.sh.erb"
  mode 0755
  owner "root"
  group "root"
end

mysql_connection = "mysql --user='root' --host='localhost' --password='#{node['mysql']['server_root_password']}'"
mysql_user = "'#{node['deploy-drupal']['install']['db_user']}'@'localhost'"

template "/usr/local/bin/drupal-reset" do
  source "drupal-reset.sh.erb"
  mode 0755
  owner "root"
  group "root"
  variables({
    :db_connection => mysql_connection,
    :db_user => mysql_user
  })
end

bash "prepare-mysql" do
  code <<-EOH
    #{mysql_connection} -e "GRANT ALL ON #{node['deploy-drupal']['install']['db_name']}.* \
    TO #{mysql_user} IDENTIFIED BY '#{node['deploy-drupal']['install']['db_pass']}'; FLUSH PRIVILEGES;"
    #{mysql_connection} -e "CREATE DATABASE IF NOT EXISTS #{node['deploy-drupal']['install']['db_name']};"
  EOH
end

conf_dir = "#{node['deploy-drupal']['drupal_root']}/sites/default"

template "settings.local.php" do
  source "settings.local.php.erb"
  path "#{conf_dir}/settings.local.php"
  mode 0460
  owner node['apache']['user']
  group node['deploy-drupal']['dev_group']
  notifies :reload, "service[apache2]"
  variables ({
    :custom_file => node['deploy-drupal']['install']['settings']
  })
end

# copies contents of default.settings.php
# removes db crendential lines, and includes local.settings.php
file "settings.php" do
  path "#{conf_dir}/settings.php" 
  content ( 
    IO.read("#{conf_dir}/default.settings.php").
    gsub(/\n\$(databases|db_url|db_prefix)\s*=.*\n/,'') +
    "\ninclude_once('settings.local.php');"
  )
  action :create_if_missing
  notifies :reload, "service[apache2]"
end


# exits with 0 if there are no tables in database
db_empty = "#{mysql_connection} -e \"SELECT * FROM information_schema.tables WHERE \
  table_type = 'BASE TABLE' AND table_schema = '#{node['deploy-drupal']['install']['db_name']}';\"\
  | wc -l | xargs test 0 -eq"

dump = node['deploy-drupal']['install']['sql_dump']
execute "populate-db" do
  # dump file path might be relative to project_root
  cwd node['deploy-drupal']['project_root']
  command "test -f '#{dump}' && zless '#{dump}' | #{mysql_connection}"
  only_if db_empty
end

# fixes sendmail error https://drupal.org/node/1826652#comment-6706102
#drush = "php -d sendmail_path=/bin/true  /usr/share/php/drush/drush.php"
drush_install = "drush site-install --debug -y\
  --account-name=#{node['deploy-drupal']['install']['admin_user']}\
  --account-pass=#{node['deploy-drupal']['install']['admin_pass']}\
  --site-name='#{node['deploy-drupal']['project_name']}'"

execute "drush-site-install" do
  cwd node['deploy-drupal']['drupal_root']
  command drush_install
  only_if db_empty
end

script = node['deploy-drupal']['install']['script']
bash "post-install" do
  # post_install_script might be relative to project_root
  cwd node['deploy-drupal']['project_root']
  code <<-EOH
    test -f #{script} && bash #{script}
    bash drupal-perm
    drush --root=#{node['deploy-drupal']['drupal_root']} cache-clear all
  EOH
end
