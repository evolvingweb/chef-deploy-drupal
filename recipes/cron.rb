## Cookbook Name:: deploy-drupal
## Recipe:: cron
##

drush = "/usr/bin/drush --root='#{node['deploy-drupal']['drupal_root']}'"
cron "drupal-cron" do
  # run cron every hour
  minute "0"
  path "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
  user node['apache']['user']
  # default value http://default is kept in drush command as a reminder that
  # $base_url is not properly populated
  command "/usr/bin/env COLUMNS=72 #{drush} --uri=http://default --quiet cron"
  only_if { File.exists?("#{node['deploy-drupal']['drupal_root']}/cron.php") }
end
