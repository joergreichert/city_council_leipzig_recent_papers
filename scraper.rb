require 'rubygems'
require 'scraperwiki'
require 'nokogiri'
# require 'html_to_plain_text'

# extrahiert die daten aus einer einzelnen tabellenzeile
def parse_row(row)
  cells = row.css('td')
  return nil if cells.nil? || cells[1].nil?
  {
    id: "https://ratsinfo.leipzig.de/bi/#{cells[1].css('a').first['href']}",
    type: 'Paper',
    # body: nil,
    name: extract_text(cells[1]),
    # reference: nil,
    publishedDate: extract_text(cells[4]),
    paperType: extract_text(cells[5]),
    # relatedPaper: [],
    # mainFile: nil,
    # auxiliaryFile: nil,
    # location: nil,
    originator: extract_text(cells[3]),
    # consultation: [],
    # underDirectionOf: [],
    # modified: nil,

    # Non Oparl fields
    # resolution: nil, # "Beschlussvorlage"
    # content: nil, # "Sachverhalt"
  }
end

# extrahiert die VOLFDNR aus einer tabellenzelle
def extract_id(cell)
  return nil if cell.nil?
  input   = cell.css('input[@name="VOLFDNR"]').first
  return nil if input.nil?
  volfdnr = input["value"]
end

# extrahiert den text aus den tabellenzellen
def extract_text(cell)
  return nil if cell.nil?
  cell.text
end

def html_to_plain_text(node)
  # TODO: Use HtmlToPlainText.plain_text(node.to_s) when it's available at morph.io – https://github.com/openaustralia/morph-docker-ruby/pull/2
  return unless node
  node.text
end

def extract_content(page)
  html = page.css('a[name="allrisSV"] ~ div:first-of-type').first
  html_to_plain_text(html)
end

def extract_resolution(page)
  html = page.css('a[name="allrisBV"] ~ div:first-of-type').first
  html_to_plain_text(html)
end

# Übersicht-Seite laden und Zeilen extrahieren
uri = "https://ratsinfo.leipzig.de/bi/vo040.asp?showall=true"
puts "Loading index page #{uri}"
html = ScraperWiki.scrape(uri)
page = Nokogiri::HTML(html)
records = page.css('table.tl1 tbody tr').map do |row|
  next if row.nil?
  parse_row(row)
end

# Detail-Seite laden und Text speichern
records.each_with_index do |record, i|
  next unless record
  uri = record[:id]
  puts "Loading details page #{i+1} of #{records.length} #{uri}"
  html = ScraperWiki.scrape(uri)
  page = Nokogiri::HTML(html)
  record[:reference] = page.css('#risname h1').text()[9..-1].strip,
  record[:content] = extract_content(page)
  record[:resolution] = extract_resolution(page)

  # Daten speichern
  ScraperWiki.save_sqlite([:id], record) unless record[:id]
end
