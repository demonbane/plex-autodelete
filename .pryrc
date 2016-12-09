require 'plex-ruby'
require 'yaml'
autodelete_config = YAML::load_file(ENV['HOME'] + '/.plex-autodelete.yml')
Plex.configure { |config| config.auth_token = autodelete_config[:token] }
server=Plex::Server.new(autodelete_config[:host], autodelete_config[:port])
shows=server.library.section(autodelete_config[:section])
