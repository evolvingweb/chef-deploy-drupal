## Cookbook Name:: deploy-drupal
## Recipe:: xhprof
##
## installs the xhprof PHP extension
## see https://www.drupal.org/node/946182 for usage with Drupal

php_pear ('xhprof') { action :install }

# we have to generate apc.ini since PHP cookbook's APC.ini breaks
template "#{node['php']['ext_conf_dir']}/xhprof.ini"  do
  source "xhprof.ini.erb"
  mode 0644
  owner "root"
  group "root"
  notifies :reload, "service[apache2]"
end
