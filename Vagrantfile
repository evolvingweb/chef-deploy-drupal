# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "precise64"
  config.vm.box_url = "http://dl.dropbox.com/u/1537815/precise64.box"
  
  config.vm.network :forwarded_port, guest: 80, host: 8080

  # precise64.box doesn't have chef 11, which we require
  config.vm.provision :shell, :inline => <<-HEREDOC
    gem install chef --version 11.0.0 --no-rdoc --no-ri --conservative
  HEREDOC

  # install some convenience tools
  config.vm.provision :shell, :inline => <<-HEREDOC
    apt-get update
    apt-get install -y curl vim git
  HEREDOC

  # Installs the previously exported site code and SQL dump via deploy-drupal::default
  config.vm.provision :chef_solo do |chef|
    chef.json.merge!({
      "deploy-drupal" => { 
        "sql_load_file" => "/vagrant/db/dump.sql.gz", # if non-existant, DB will be initialized via 'drush si'
        "codebase_source_path" =>  "/vagrant/site", # if folder is empty, will download D7 instead
        "dev_group" => 'sudo' # TODO: 'sudo' should be default (group that owns Drupal codebase; vagrant user must be in it)
      },
      "mysql" => {
        "server_root_password" => "root",
        "server_debian_password" => "root",
        "server_repl_password" => "root"
      },
      "minitest" =>{
        "recipes" => [ "deploy-drupal" ]
      },
      "run_list" =>[ "deploy-drupal", "minitest-handler" ]
    })
  end
end
