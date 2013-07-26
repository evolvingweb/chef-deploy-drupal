# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure('2') do |config|
  config.vm.box = 'precise64-dev'
  config.vm.box_url = 'https://s3.amazonaws.com/vagrant-drupal/precise64-dev.box'
  
  config.vm.network :forwarded_port, guest: 80,   host: 8000    #nginx
  config.vm.network :forwarded_port, guest: 8000, host: 8001    #apache
  # precise64.box doesn't have chef 11, which we require
  config.vm.provision :shell, :inline => <<-HEREDOC
    gem install chef --version 11.0.0 --no-rdoc --no-ri --conservative
  HEREDOC
  config.vm.provision :chef_solo do |chef|
    chef.add_recipe 'deploy-drupal'
    chef.add_recipe 'deploy-drupal::nginx'
    chef.add_recipe 'minitest-handler'
    chef.log_level= :debug
    chef.json.merge!({
      'deploy-drupal' => { 
        'dev_group' => 'vagrant',
        'apache_port' => '8000',
        'nginx' => { 
          'custom_blocks_file' => 'block_china'
        },
        'version' => '6'
      },
      'apache' => {
        'listen_ports' => ['8000'],
      },
      'nginx' => {
        'default_site_enabled' => false,
        'gzip' => 'on',
      },
      'mysql' => {
        'server_root_password' => 'root',
        'server_debian_password' => 'root',
        'server_repl_password' => 'root'
      },  
      'minitest' =>{ 
        'recipes' => [ 'deploy-drupal', 'deploy-drupal::nginx']
      }
    })   
  end
end
