require "thor"

class Error < Thor::Error; end

# TODO
# - Login
# - Update summary
# - Parralelize TMDB calls
# - Check US availability?

module Lebowski
  class Cli < Thor
    desc 'diff', 'Diff!'
    option :pretty, :type => :boolean
    def diff(from_path, to_path)
      from_watchlist = Lebowski::Watchlist.new(JSON.load_file(from_path))
      to_watchlist = Lebowski::Watchlist.new(JSON.load_file(to_path))

      puts from_watchlist.diff(to_watchlist)
        .to_json(pretty: options[:pretty])
    end

    desc 'watchlist', 'Show watchlist'
    option :'with-providers', :type => :boolean
    option :'with-people', :type => :boolean
    option :pretty, :type => :boolean
    def watchlist
      puts Lebowski::Watchlist
        .fetch(
          with_providers: options[:'with-providers'],
          with_people: options[:'with-people']
        )
        .to_json(pretty: options[:pretty])
    end

    desc 'providerlist', 'Provider List'
    option :pretty, :type => :boolean
    def providerlist(watchlist_path)
      watchlist = Lebowski::Watchlist.new(JSON.load_file(watchlist_path))

      puts Lebowski::Providerlist.new(watchlist)
        .to_json(pretty: options[:pretty])
    end

    desc 'generate', 'Generate'
    def generate
      Lebowski::Generate.run
    end
  end
end
