require 'plex-ruby'
require 'yaml'
require './lib/plex/episode.rb'
require './lib/plex/season.rb'
require './lib/plex/show.rb'

autodelete_config = YAML::load_file(ENV['HOME'] + '/.plex-autodelete.yml')
Plex.configure { |config| config.auth_token = autodelete_config[:token] }
server=Plex::Server.new(autodelete_config[:host], autodelete_config[:port])
shows=server.library.section(autodelete_config[:section])
