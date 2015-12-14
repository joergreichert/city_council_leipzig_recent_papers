require 'scraperwiki'
require 'nokogiri'

class Page
  attr_reader :uri

  def initialize(uri, fetcher: ScraperWikiFetcher)
    @uri = uri
    @fetcher = fetcher
  end

  def expand_link(link_path)
    "#{base_path}/#{link_path}"
  end

  def base_path
    uri.split('/')[0..-2].join('/')
  end

  def doc
     @doc ||= begin
      puts "Load #{self.class} from #{uri}"
      Nokogiri::HTML(@fetcher.fetch(uri))
    end
  end
end

class ScraperWikiFetcher
  def self.fetch(uri)
    ScraperWiki.scrape(uri)
  end
end

class FixtureFetcher
  require 'base64'

  def self.fetch(uri)
    filename = Base64.strict_encode64(uri)
    File.read("#{__dir__}/../fixtures/#{filename}")
  end
end

class CalendarPage < Page
  def meetings
    links = doc.css("table.tl1 a:contains('Ratsversammlung')")
    links.map{|link|
      {
        id: expand_link(link['href']),
        type: "oparl:Meeting",
        name: link.text,
      }
    }
  end
end
