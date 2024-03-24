watchlist:
	bundle exec dotenv bin/lebowski watchlist

providerlist:
	bundle exec dotenv bin/lebowski providerlist

diff:
	bundle exec dotenv bin/lebowski diff

updates:
	bundle exec dotenv bin/lebowski updates

site-watchlist:
	bundle exec dotenv bin/lebowski watchlist | sponge site/data/watchlist.json

site-providerlist:
	bundle exec dotenv bin/lebowski providerlist | sponge site/data/providerlist.json

site-diff:
	bundle exec dotenv bin/lebowski diff | sponge  site/data/diff.json

site-updates:
	bundle exec dotenv bin/lebowski updates | sponge site/data/updates.json

fetch: fetch-updates fetch-diff fetch-providerlist fetch-watchlist fetch-old

fetch-watchlist:
	wget -O site/data/watchlist.json https://shanesmith.github.io/lebowski/data/watchlist.json

fetch-providerlist:
	wget -O site/data/providerlist.json https://shanesmith.github.io/lebowski/data/providerlist.json

fetch-updates:
	wget -O site/data/updates.json https://shanesmith.github.io/lebowski/data/updates.json

fetch-diff:
	wget -O site/data/diff.json https://shanesmith.github.io/lebowski/data/diff.json

fetch-old-providerlist:
	wget -O site/data/old.json https://shanesmith.github.io/lebowski/data/old-providerlist.json
