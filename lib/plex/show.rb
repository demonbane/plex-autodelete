module Plex
  class Show
    def watched_seasons?
      watched_seasons.size > 0
    end

    def watched_seasons
      seasons.select { |season| season.watched_episodes.size > 0 }
    end

    def episodes
      seasons.flat_map { |season| season.episodes }
    end

    def watched_episodes
      seasons.flat_map { |season| season.watched_episodes }
    end

    def unwatched_episodes
      seasons.flat_map { |season| season.unwatched_episodes }
    end

    def episodes_older_than(date)
      episodes.select { |episode| Time.at(episode.added_at.to_i).to_date < date }
    end
  end
end
