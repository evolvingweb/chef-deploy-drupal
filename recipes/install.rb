## Cookbook Name:: deploy-drupal
## Recipe:: install
##

mysql_connection = "mysql --user='root' --host='localhost' --password='#{node['mysql']['server_root_password']}'"
db_user = "'#{node['deploy-drupal']['install']['db_user']}'@'localhost'"
db_pass = node['deploy-drupal']['install']['db_pass']
db_name = node['deploy-drupal']['install']['db_name']

ruby_block "find-drupal-version" do
  docroot = node['deploy-drupal']['drupal_root']
  drush_sed = 's/.*"drupal-version":"\([0-9]\+\.[0-9]\+\)".*/\1/'
  drush_cmd = "drush --root=#{docroot} status --format=json | sed '#{drush_sed}'"
  # in the common case that settings.php is commited to the repo and settings.local.php
  # is not, `drush status` will fail. Fallback on insepcting CHANGELOG.txt
  changelog_sed = 's/Drupal\s\([0-9]\+\.[0-9]\+\).*/\1/'
  changelog_cmd = "grep -m 1 Drupal #{docroot}/CHANGELOG.txt | sed '#{changelog_sed}'"
  block do
    version = Mixlib::ShellOut.new(drush_cmd).run_command.stdout.strip
    # fallback on CHANGELOG.txt if drush command did not return proper version
    version = Mixlib::ShellOut.new(changelog_cmd).run_command.stdout.strip if version !~ /\d+\.\d+/
    # ser attribute value only if we found a proper version
    node.set['deploy-drupal']['version'] = version if (version =~ /\d+\.\d+/)
  end
end

web_app node['deploy-drupal']['project_name'] do
  template "web_app.conf.erb"
  listen_port node['deploy-drupal']['apache_port']
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
# unset db crendential variables, and include local.settings.php
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
  notifies :run, "bash[finish-provision]", :immediately
  notifies :run, "execute[post-install-script]"
end

# workaround for drush trying to send e-mails during site-install
# see https://drupal.org/node/1826652
drush_si = "PHP_OPTIONS='-d sendmail_path=/bin/true' drush site-install"
drush_si_opts = ['--debug', '-y']
drush_si_opts << "--account-name=#{node['deploy-drupal']['install']['admin_user']}"
drush_si_opts << "--account-pass=#{node['deploy-drupal']['install']['admin_pass']}"
drush_si_opts << "--site-name='#{node['deploy-drupal']['project_name']}'"

execute "drush-site-install" do
  cwd node['deploy-drupal']['drupal_root']
  command "#{drush_si} #{drush_si_opts.join(' ')}"
  only_if db_empty
  notifies :run, "execute[post-install-script]"
end

# the following resource is executed on every provision
bash "finish-provision" do
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
  # post install script might be relative to project_root
  cwd node['deploy-drupal']['project_root']
  command "bash '#{script_file}'"
  only_if "test -f '#{script_file}'", :cwd => node['deploy-drupal']['project_root']
  action :nothing
end
