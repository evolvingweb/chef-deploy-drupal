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
    chef.json.merge!({
      'deploy-drupal' => { 
        'dev_group_name' => 'vagrant',
        'sql_load_file' => 'db/dump.sql.gz',
        'get_project_from' => { :path => '/vagrant/prj-jul8' },
        'apache_port' => '8000',
        'nginx_port' => '80',
      },
      'apache' => {
        'listen_ports' => ['8000']
      },
      'nginx' => {
        'default_site_enabled' => false,
      },
      'mysql' => {
        'server_root_password' => 'root',
        'server_debian_password' => 'root',
        'server_repl_password' => 'root'
      },  
      'minitest' =>{ 
        'recipes' => [ 'deploy-drupal' ],
        'drupal_site_dir' => '/var/shared/sites/cooked.drupal/site'
      },  
      'run_list' =>[ 'deploy-drupal::nginx', 'minitest-handler' ]
    })   
  end
end
