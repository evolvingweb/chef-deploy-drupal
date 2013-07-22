## Cookbook Name:: deploy-drupal
## Recipe:: download_drupal
##
## download drupal if necessary

=begin
repourl = "http://ftp.drupal.org/files/projects"
case node['deploy-drupal']['version']
when '7' 
  version = '7.22'
when '6'
  version = '6.28'
else 
  version = node['deploy-drupal']['version']
end

project_missing = node['deploy-drupal']['get_project']['path'].empty? &&
                  node['deploy-drupal']['get_project']['git'].empty?
=end
# temporary project directory where drupal will be downloaded
tmp_dir = "#{Chef::Config[:file_cache_path]}/#{node['deploy-drupal']['project_name']}"

#directory "/tmp/vagrant-chef-1/cooked.drupal/site" do
directory "#{tmp_dir}/site" do
  recursive true
end

execute "download-drupal" do
  command "cd #{tmp_dir}/tmp/vagrant-chef-1/cooked.drupal; curl http://ftp.drupal.org/files/projects/drupal-7.22.tar.gz | tar xz -C site --strip-components=1"
  only_if { node['deploy-drupal']['get_project']['path'].empty? && node['deploy-drupal']['get_project']['git'].empty? }
#only_if { project_missing }
end

#if project_missing
 # node.set['deploy-drupal']['get_project']['path'] = tmp_dir
#end
