## Cookbook Name:: deploy-drupal
## Recipe:: apc
##
## install and configure APC

# NOTE changing the directives in dna.json does not update apc.ini if APC is
# already installed.
php_pear 'apc' do
  action :install
  directives(node['deploy-drupal']['apc_directives'])
end
