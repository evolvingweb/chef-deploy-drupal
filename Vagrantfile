# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "precise64"
  config.vm.box_url = "http://dl.dropbox.com/u/1537815/precise64.box"
  
  config.vm.network :forwarded_port, guest: 80, host: 8080

  # precise64.box doesn't have chef 11, which we require
  config.vm.provision :shell, :inline => <<-HEREDOC
    apt-get install -y curl vim git
    gem install chef --version 11.0.0 --no-rdoc --no-ri --conservative
  HEREDOC
  
  config.vm.provision :chef_solo do |chef|
    reset = ENV["reset"].nil? ? "" : ENV["reset"]
    chef.json.merge!({
      "deploy-drupal" => { 
        "sql_load_file" => "db/dump.sql.gz",
        "source_project_path" => "/vagrant",
        "dev_group_name" => "vagrant",
        "reset" => reset
      },  
      "mysql" => {
        "server_root_password" => "root",
        "server_debian_password" => "root",
        "server_repl_password" => "root"
      },  
      "minitest" =>{ 
        "recipes" => [ "deploy-drupal" ],
        "drupal_site_dir" => "/var/shared/sites/cooked.drupal/site"
      },  
      "run_list" =>[ "deploy-drupal", "minitest-handler" ]
    })   
  end
end
