data:
	bundle exec dotenv bin/lebowski tmdb

site-data:
	bundle exec dotenv bin/lebowski tmdb > site/data.json

fetch: fetch-updates fetch-diff fetch-data

fetch-updates:
	wget -O site/updates.json https://shanesmith.github.io/lebowski/updates.json

fetch-diff:
	wget -O site/diff.json https://shanesmith.github.io/lebowski/diff.json

fetch-data:
	wget -O site/data.json https://shanesmith.github.io/lebowski/data.json
