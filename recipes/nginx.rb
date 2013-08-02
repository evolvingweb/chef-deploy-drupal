## Cookbook Name:: deploy-drupal
## Recipe:: nginx
##
## set up an Nginx server in front of Apache 

# assemble all necessary query strings and paths
include_recipe 'nginx::default'

conf_file = node['nginx']['dir'] + "/sites-available/" + 
            node['deploy-drupal']['project_name']
# the following strings must be assembled using single quotes
# as they will be used as pcre regular expressions for nginx
ext_list = '\.(' + node['deploy-drupal']['nginx']['extension_block_list'].join('|') + ')$'
location_list = '^(' +  node['deploy-drupal']['nginx']['location_block_list'].join('|') + ')$'
keyword_list = '(' + node['deploy-drupal']['nginx']['keyword_block_list'].join('|') + ')'
static_list = '\.(' + node['deploy-drupal']['nginx']['static_content'].join('|') + ')(\.gz)?$'
# custom blocks file might be relative to project root
custom_file = node['deploy-drupal']['nginx']['custom_site_file']
if custom_file[0] == '/' 
  custom_file = "#{node['deploy-drupal']['project_root']}/#{custom_file}"
end
# load the nginx site template
template conf_file do
  source "nginx_site.conf.erb"
  mode 0644
  owner "root"
  group "root"
  variables({
    :ext_list => ext_list,
    :location_list => location_list,
    :keyword_list => keyword_list,
    :static_list => static_list,
    :custom_file => custom_file
  })
  notifies :reload, "service[nginx]"
end

# by default is set to enabled = true and timing = delayed
nginx_site node['deploy-drupal']['project_name'] do
end
