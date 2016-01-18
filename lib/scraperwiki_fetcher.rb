require 'scraperwiki'

class ScraperWikiFetcher
  def self.fetch(uri)
    ScraperWiki.scrape(uri)
  end
end
