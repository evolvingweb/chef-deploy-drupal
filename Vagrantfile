# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure('2') do |config|
  config.vm.box = 'precise64'
  config.vm.box_url = 'http://dl.dropbox.com/u/1537815/precise64.box'

  config.vm.network :forwarded_port, guest: 80,   host: 8000    #nginx
  config.vm.network :forwarded_port, guest: 8000, host: 8001    #apache

  config.vm.synced_folder './db', '/home/vagrant/drush-backups/'
  # precise64.box doesn't have chef 11, which we require
  config.vm.provision :shell, :inline => <<-HEREDOC
    gem install chef --version 11.0.0 --no-rdoc --no-ri --conservative
  HEREDOC

  config.vm.provision :chef_solo do |chef|
    chef.add_recipe 'deploy-drupal::default'
    chef.add_recipe 'deploy-drupal::nginx'
    chef.add_recipe 'minitest-handler'

    chef.json.merge!({
      'deploy-drupal' => {
        'dev_group' => 'vagrant',
        'apache_port' => '8000',
        'writable_dirs' => [ "sites/default/files", "cache" ]
      },
      'apache' => {
        'listen_ports' => ['8000'],
        'default_site_enabled' => false,
      },
      'nginx' => {
        'default_site_enabled' => false,
        'gzip' => 'on',
      },
      'mysql' => {
        'server_root_password' => 'root',
        'server_debian_password' => 'root',
        'server_repl_password' => 'root',
      },
      'memcached' => {
        'listen' => '127.0.0.1'
      },
      'minitest' =>{
        'recipes' => [ 'deploy-drupal::default' , 'deploy-drupal::nginx', ],
      }
    }) 
  end
end
