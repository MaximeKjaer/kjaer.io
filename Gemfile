source "https://rubygems.org"

gem "jekyll", "~> 4.0.0"
group :jekyll_plugins do
  gem "jekyll-sitemap", "~> 1.4.0"
  gem "jekyll-feed"
  gem "jekyll-mathjax-csp", "~> 1.3.1"
  gem "jekyll-diagrams", "~> 0.5.0"
  gem "jekyll-block", "~> 0.0.1"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: [:mingw, :mswin, :x64_mingw, :jruby]

# Performance-booster for watching directories on Windows
gem "wdm", "~> 0.1.0" if Gem.win_platform?


group :test do
	# For testing outputted HTML on Travis CI
	gem "rake"
	gem "html-proofer"
end
