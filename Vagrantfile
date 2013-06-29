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
  
  config.vm.provision :chef_solo do |chef|
    chef.json.merge!({
      "deploy-drupal" => { 
        "sql_load_file" => "db/dump.sql.gz",
        "source_project_path" =>  "/vagrant",
        "source_site_path"  => "my_site",
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
