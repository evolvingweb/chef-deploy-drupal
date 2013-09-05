## Cookbook Name:: deploy-drupal
## Recipe:: apc
##
## install and configure APC

php_pear "APC" do
  action :install
  # directives ( node['deploy-drupal']['apc'] )
end

# we have to generate apc.ini since PHP cookbook's APC.ini breaks
template "#{node['php']['ext_conf_dir']}/apc.ini"  do
  source "apc.ini.erb"
  mode 0644
  owner "root"
  group "root"
  notifies :reload, "service[apache2]"
end
