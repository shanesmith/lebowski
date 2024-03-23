data:
	bundle exec dotenv bin/lebowski providers

diff:
	bundle exec dotenv bin/lebowski diff

updates:
	bundle exec dotenv bin/lebowski updates

site-data:
	bundle exec dotenv bin/lebowski providers | sponge site/data.json

site-diff:
	bundle exec dotenv bin/lebowski diff | sponge  site/diff.json

site-updates:
	bundle exec dotenv bin/lebowski updates | sponge site/updates.json

fetch: fetch-updates fetch-diff fetch-data fetch-old

fetch-updates:
	wget -O site/updates.json https://shanesmith.github.io/lebowski/updates.json

fetch-diff:
	wget -O site/diff.json https://shanesmith.github.io/lebowski/diff.json

fetch-data:
	wget -O site/data.json https://shanesmith.github.io/lebowski/data.json

fetch-old:
	wget -O site/old.json https://shanesmith.github.io/lebowski/old.json
