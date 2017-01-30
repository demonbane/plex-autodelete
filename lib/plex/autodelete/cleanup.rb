require "plex/autodelete/version"
require "plex-ruby"
require "filesize"
require "fileutils"
require "plex/episode"
require "plex/season"
require "plex/show"

module Plex
  module Autodelete
    attr_accessor :fileutils
    module_function :fileutils, :fileutils=

    class Cleanup
      SAFE_MODE_MESSAGE="Running in safe mode, use '--delete' to delete files"

      @stats = {
        total: 0,
        deleted: 0,
        failed: 0,
        size: 0,
        skipped: 0,
        unwatched: 0
      }

      @config = {
        host: '127.0.0.1',
        port: 32400,
        token: nil,
        skip: [],
        #delete: false,
        section: 1,
        cron: false,
        #verbose: false
      }

      @config_keys = @config.keys

      @captured_output = StringIO.new
      Plex::Autodelete.fileutils = FileUtils::NoWrite

      def self.configure(opts = {})
        opts.each { |key, value| @config[key.to_sym] = value }
      end

      def self.cleanup
        self.required_params!

        String.disable_colorization = true unless $stdout.isatty
        if @config[:cron]
          $stdout = @captured_output
        end

        puts @config.to_yaml if self.verbose?

        if @config[:delete]
          Plex::Autodelete.fileutils = FileUtils
        else
          puts SAFE_MODE_MESSAGE.green
        end

        self.plex_server.library.section(@config[:section]).all.each do |show|
          self.increment_stat :total, show.episodes.size

          puts nil if self.verbose?
          show_name = "#{show.title}".bold + " - "

          if @config[:skip].include? show.title
            puts show_name + "Skipped".blue if self.verbose?
            self.increment_stat :skipped, show.episodes.size
          elsif not show.watched_seasons? and not @config[:daily].include? show.title
            puts show_name + "Not watched yet".blue if self.verbose?
            self.increment_stat :unwatched, show.unwatched_episodes.size
          elsif show.watched_seasons? or @config[:daily].include? show.title
            #Set automatically forces uniq on an array
            episodes_to_delete = show.watched_episodes.to_set
            if @config[:daily].include? show.title
              episodes_to_delete += show.episodes_older_than(Date.today - @config[:daily_days])
            end
            puts show_name + sprintf("Deleting %d/%d episodes\n", episodes_to_delete.size, show.episodes.size) unless episodes_to_delete.empty?
            show.episodes.each do |episode|
              if episodes_to_delete.include? episode
                self.delete_episode episode
              elsif self.verbose?
                puts sprintf("  S%02dE%02d - %s - Not watched yet", episode.season.index, episode.index, episode.title).blue
              end
            end
          end
        end

        self.output_stats

        if @config[:cron]
          if @stats[:deleted] > 0 or @stats[:failed] > 0
            STDOUT.puts @captured_output.string
          end
        end
      end

      private

      def self.verbose?
        if @config[:verbose]
          true
        elsif @config[:verbose] == false
          false
        elsif @config[:verbose].nil? and @config[:delete]
          false
        elsif @config[:verbose].nil?
          true
        end
      end

      def self.required_params!
        [:host, :port, :token, :section].each do |param|
          if @config[param].nil?
            raise Exception
          end
        end
      end

      def self.plex_server
        Plex.configure do |config|
          config.auth_token = @config[:token]
        end

        Plex::Server.new(@config[:host], @config[:port])
      end

      def self.delete_episode episode
        episode_name = sprintf("  S%02dE%02d - %s", episode.season.index, episode.index, episode.title).yellow
        if File.exist? episode.part_files.first
          episode.part_files.each do |filename|
            begin
              filesize = File.size(filename)
              Plex::Autodelete.fileutils.rm(filename)
              puts episode_name
              self.increment_stat :deleted
              self.increment_stat :size, filesize
            rescue Errno::ENOENT => e
              puts "  Failed - ('#{filename}' not found)".red
              self.increment_stat :failed
            rescue Errno::EACCES => e
              puts "  Failed - ('#{filename}' permission denied)".red
              self.increment_stat :failed
            end
          end
        else
          # Try deleting via the API
          if episode.delete!
            puts episode_name
            self.increment_stat :deleted
            self.increment_stat :size, episode.parts_size
          else
            self.increment_stat :failed
          end
        end
      end

      def self.increment_stat stat, amount=1
        @stats[stat] += amount
      end

      def self.output_stats
        puts nil
        puts '-------------'
        puts '    Stats    '
        puts '-------------'
        puts SAFE_MODE_MESSAGE.green unless @config[:delete]
        puts "Total Episodes:   #{@stats[:total].to_i}"
        puts "     Unwatched:   #{@stats[:unwatched].to_i}"
        puts "       Skipped:   #{@stats[:skipped].to_i}".blue
        puts "       Deleted:   #{@stats[:deleted].to_i}".yellow
        puts "        Failed:   #{@stats[:failed].to_i}".red if @stats[:failed] > 0
        puts "          Size:   #{Filesize.from(@stats[:size].to_s + " B").pretty}"
        puts nil
      end

    end
  end
end
