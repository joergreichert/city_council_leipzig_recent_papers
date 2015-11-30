require 'rubygems'
require 'scraperwiki'
require 'nokogiri'
require 'yaml'
require 'html_to_plain_text'
require 'active_support/core_ext/string'

module Scraper
  module_function

  def config
    @config ||= YAML.load(File.read('./config.yml'))
  end

  def expand_uri(path)
    "#{config['base_uri']}/#{path}"
  end
end

class Page < Struct.new(:uri)
  def doc
    @doc ||= begin
      puts "Load #{self.class} from #{uri}"
      Nokogiri::HTML(ScraperWiki.scrape(uri))
    end
  end
end

class PaperIndex < Page
  def papers
    rows = doc.css('table.tl1 tbody tr')
    rows = rows.take(Scraper.config['recent_papers_limit'])
    rows.map! do |row|
      parse_row_to_paper(row)
    end.compact!
  end

  private

  # extrahiert daten aus einer einzelnen tabellenzeile
  def parse_row_to_paper(row)
    # FIXME: Remove cowardice conditionals
    cells = row.css('td')
    return nil if cells.nil? || cells[1].nil?
    url = Scraper.expand_uri(cells[1].css('a').first['href'])
    published_at = extract_text(cells[4])

    Paper.new(url, attributes: {
      body: Scraper.config['body'],
      published_at: (Date.parse(published_at) unless published_at.empty?),
      paper_type: extract_text(cells[5]),
      originator: extract_text(cells[3]),
    })
  end

  # extrahiert den text aus den tabellenzellen
  def extract_text(cell)
    return nil if cell.nil?
    cell.text
  end
end

class Paper < Page
  def initialize(uri, attributes: {})
    super(uri)
    @predefined_attributes = attributes
  end

  def reference
    doc.css('#risname').first.text.match(/(Vorlage - )(.*)/)[2].squish
  end

  def name
    html = doc.css('.ko1 td:contains("Betreff:") ~ td').first
    html_to_plain_text(html).chomp(' |')
  end

  def body
    # TODO: What's the body here?
    'Halle'
  end

  def content
    html = doc.css('a[name="allrisSV"] ~ div:first-of-type').first
    text = html_to_plain_text(html)
    text && text.match(/(\-*)(.*)/)[2]
  end

  def resolution
    html = doc.css('a[name="allrisBV"] ~ div:first-of-type').first
    html_to_plain_text(html)
  end

  def scraped_at
    Time.now
  end

  def published_at
    date = doc.css('#smctablevorgang .smctablehead:contains("Datum") ~ td').text.squish
    Date.parse(date) if date.present?
  end

  def paper_type
    doc.css('#smctablevorgang .smctablehead:contains("Art") ~ td').text.squish
  end

  def originator
  end

  def under_direction_of
  end

  def attributes
    @attributes ||= {
      id: uri,
      url: uri,
      reference: reference,
      name: name,
      body: body,
      content: content,
      resolution: resolution,
      scraped_at: scraped_at,
      published_at: published_at,
      paper_type: paper_type,
      originator: originator,
      under_direction_of: under_direction_of,
    }.merge!(@predefined_attributes)
  end

  private

  def html_to_plain_text(node)
    return unless node
    HtmlToPlainText.plain_text(node.to_s)
  end
end

ScraperWiki.config = { db: 'data.sqlite' }

index = PaperIndex.new(Scraper.expand_uri(Scraper.config['recent_papers_path']))
index.papers.each do |paper|
  paper.attributes
  ScraperWiki.save_sqlite([:id], paper.attributes, 'data')
end
