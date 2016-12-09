module Plex
  class Episode
    def watched?
      respond_to?(:view_count) and view_count.to_i > 0
    end

    def part_files
      medias.flat_map { |media| media.parts.map { |part| part.file } }
    end

    def parts
      medias.flat_map { |media| media.parts }
    end

    def parts_size
      parts.inject { |sum, part| sum + part.size.to_i }
    end

    def delete!
      season.delete_episode(self)
    end
  end
end
