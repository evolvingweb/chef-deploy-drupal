## Cookbook Name:: deploy-drupal
## Recipe:: apc
##
## install and configure APC

execute "install-apc" do
  # pecl install initiates prompts that we do not want to interact with
  # pecl upgrade is the idempotent version of pecl install
  command 'printf "\n" | pecl upgrade apc'
end

# we have to generate apc.ini since PHP cookbook's APC.ini breaks
template "#{node['php']['ext_conf_dir']}/apc.ini"  do
  source "apc.ini.erb"
  mode 0644
  owner "root"
  group "root"
  notifies :reload, "service[apache2]"
end
