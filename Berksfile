site :opscode
#metadata
group :deploy do
  cookbook 'drush', :git => 'git://github.com/homemade/chef-drush.git'
  cookbook 'xhprof', :git => 'git://github.com/msonnabaum/chef-xhprof.git'
  cookbook 'deploy_drupal', :path => 'site-cookbooks/deploy_drupal'
end

group :test do
  cookbook 'minitest-handler'
end
