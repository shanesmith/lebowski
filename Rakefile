$LOAD_PATH.unshift(File.expand_path("../lib/", __FILE__))

require "lebowski"

github_conn = Faraday.new(Lebowski::Generate::GITHUB_HOST) do |conn|
  conn.response :json
  conn.response :raise_error
end

namespace "fetch" do
  fetch_map = {
    watchlist:           Lebowski::Generate::WATCHLIST_PATH,
    providerlist:        Lebowski::Generate::PROVIDERLIST_PATH,
    'old-watchlist':     Lebowski::Generate::OLD_WATCHLIST_PATH,
    'updates-watchlist': Lebowski::Generate::UPDATES_WATCHLIST_PATH,
  }

  task all: fetch_map.keys

  fetch_map.each do |name, path|
    task name do
      puts "fetching #{name}"
      File.write(
        Lebowski::Generate.site_path(path),
        github_conn.get(path).body.to_json
      )
    end
  end
end
