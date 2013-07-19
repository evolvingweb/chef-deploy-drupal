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
        'dev_group_name' => 'vagrant',
        'apache_port' => '8000',
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
      'minitest' =>{ 
        'recipes' => [ 'deploy-drupal::default' , 'deploy-drupal::nginx' ],
        # update following line if you change any of the following attributes:
        # deploy_dir, project_name, drupal_root_dir
        'drupal_site_dir' => '/var/shared/sites/cooked.drupal/site'
      },  
      'run_list' =>[ 'deploy-drupal::nginx', 'minitest-handler' ]
    })   
  end
end
