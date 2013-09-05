name             "deploy-drupal"
maintainer       "Amir Kadivar"
maintainer_email "amir@evolvingweb.ca"
license          "Apache 2.0"
description      "Installs/Configures/Bootsraps Drupal"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.0.1"

depends "apt"
depends "build-essential"
depends "git"
depends "vim"
depends "curl"
depends "apache2"
depends "php"
depends "memcached"
depends "drush"
depends "mysql"
depends "xhprof"
depends "nginx"
