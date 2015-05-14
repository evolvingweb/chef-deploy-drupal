# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure('2') do |config|
  config.vm.box = 'hashicorp/precise64'
  config.vm.box_url = 'https://atlas.hashicorp.com/hashicorp/boxes/precise64'

  config.vm.network :forwarded_port, guest: 80,   host: 11000    #nginx
  config.vm.network :forwarded_port, guest: 8000, host: 11001    #apache

  # config.vm.synced_folder './db', '/home/vagrant/drush-backups/'
  # precise64.box doesn't have chef 11, which this cookbook requires
  # precise64.box also uses Ruby 1.8.7 which breaks certain cookbooks
  # using Ruby 1.9 specific syntax
  config.vm.provision :shell, :inline => <<-HEREDOC
    apt-get update
    apt-get install -q -y ruby1.9.1 ruby1.9.1-dev build-essential
    gem install chef --version '>=11.0.0' --no-rdoc --no-ri --conservative
    # NOTE uncomment the following to use librarian-chef instead of vagrant-berkshelf
    # apt-get install -y git && gem install librarian-chef
    # cd /vagrant ; rm -f Cheffile.lock; librarian-chef install
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
        'recipes' => [ 'deploy-drupal::default' ] #, 'deploy-drupal::nginx', ],
      }
    })
    # see https://github.com/mitchellh/vagrant/issues/4270
    chef.custom_config_path = 'Vagrantfile.chef'
  end
end
