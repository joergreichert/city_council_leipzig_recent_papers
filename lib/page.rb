require 'scraperwiki_fetcher'

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
