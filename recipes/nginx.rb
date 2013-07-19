## Cookbook Name:: deploy-drupal
## Recipe:: nginx
##
## set up an Nginx server in front of Apache 

# assemble all necessary query strings and paths
include_recipe 'nginx::default'

NGINX_SITE_FILE     = node['nginx']['dir'] + "/sites-available/" + 
                      node['deploy-drupal']['project_name']

# the following strings must be assembled using single quotes
# as they will be used as pcre regular expressions for nginx
EXTENSION_BLOCK_LIST= '\.(' +
                      node['deploy-drupal']['nginx']['extension_block_list'].join('|')+
                      ')$'
LOCATION_BLOCK_LIST = '^(' +
                      node['deploy-drupal']['nginx']['location_block_list'].join('|') +
                      ')$'
KEYWORD_BLOCK_LIST  = '(' +
                      node['deploy-drupal']['nginx']['keyword_block_list'].join('|') +
                      ')'
STATIC_CONTENT      = '\.(' +
                      node['deploy-drupal']['nginx']['static_content'].join('|')+
                      ')(\.gz)?$'
# load the nginx site template
template NGINX_SITE_FILE do
  source "nginx_site.conf.erb"
  mode 0644
  owner "root"
  group "root"
  variables({
    :pcre_extension_block_list => EXTENSION_BLOCK_LIST,
    :pcre_location_block_list => LOCATION_BLOCK_LIST,
    :pcre_keyword_block_list => KEYWORD_BLOCK_LIST,
    :pcre_static_content => STATIC_CONTENT
  })
  notifies :reload, "service[nginx]", :delayed
end

# by default is set to enabled = true and timing = delayed
nginx_site node['deploy-drupal']['project_name'] do
end
