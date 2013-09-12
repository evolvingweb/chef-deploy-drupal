## Cookbook Name:: deploy-drupal
## Recipe:: nginx
##
## set up an Nginx server in front of Apache 

# assemble all necessary query strings and paths
include_recipe 'nginx::default'
conf_file = node['nginx']['dir'] + "/sites-available/" + 
            node['deploy-drupal']['project_name']


custom_file = node['deploy-drupal']['nginx']['custom_site_file']
if custom_file.nil? then
  template conf_file do
    source "nginx_site.conf.erb"
    mode 0644
    owner "root"
    group "root"
    variables ({ 'custom_file' => custom_file })
    notifies :reload, "service[nginx]"
  end
else
  # custom blocks file might be relative to project root
  if ( custom_file[0] != '/' )
    custom_file = "#{node['deploy-drupal']['project_root']}/#{custom_file}"
  end
  execute "copy-nginx-site-file" do
    user "root"
    command "cp #{custom_file} #{conf_file}"
    only_if "test -f #{custom_file}"
    notifies :reload, "service[nginx]"
  end
end



# by default is set to enabled = true and timing = delayed
nginx_site node['deploy-drupal']['project_name'] do
end

# install Apacahe rpaf module for remote address resolution behind reverse proxy
package value_for_platform(
  [ 'centos', 'redhat', 'fedora' ] => { 'default' => 'dba-apache2-mod_rpaf' },
  [ 'debian', 'ubuntu' ] => { 'default' => 'libapache2-mod-rpaf' }
)
# write over rpaf.conf to work around
# https://bugs.launchpad.net/ubuntu/+source/libapache2-mod-rpaf/+bug/1002571
template "#{node['apache']['dir']}/mods-available/rpaf.conf" do
  source "rpaf.conf.erb"
  mode 0644
  owner "root"
  group "root"
  notifies :reload, "service[apache2]"
end
