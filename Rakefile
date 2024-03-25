$LOAD_PATH.unshift(File.expand_path("../lib/", __FILE__))

require "lebowski"

github_conn = Faraday.new(Lebowski::Generate::GithubHost) do |conn|
  conn.response :json
  conn.response :raise_error
end


namespace "fetch" do
  fetch_map = {
    watchlist:           Lebowski::Generate::WatchlistPath,
    providerlist:        Lebowski::Generate::ProviderlistPath,
    'old-watchlist':     Lebowski::Generate::OldWatchlistPath,
    'updates-watchlist': Lebowski::Generate::UpdatesWatchlistPath,
  }

  task all: fetch_map.keys

  fetch_map.each do |name, path|
    puts "fetching #{name}"
    task name do
      File.write(
        Lebowski::Generate.site_path(path),
        github_conn.get(path).body.to_json
      )
    end
  end
end
