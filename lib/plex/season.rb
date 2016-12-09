require 'rest-client'

module Plex
  class Season
    def unwatched_episodes
      episodes.select { |episode| not episode.watched? }
    end

    def watched_episodes
      episodes.select { |episode| episode.watched? }
    end

    def delete_episode(episode)
      #RestClient.delete(episode.url + episode.key, {"X-Plex-Token" => Plex.config.auth_token})
      puts "Calling RestClient.delete(#{episode.url + episode.key}, {\"X-Plex-Token\" => #{Plex.config.auth_token}})"
      @episodes.delete(episode)
    rescue RestClient::RequestFailed => e
      puts "  Failed - ('#{episode.title}' API: #{e.message})".red
    end
  end
end
