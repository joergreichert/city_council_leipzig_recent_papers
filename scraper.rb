# ein kleiner scraper für das ratsinformations-system der stadt leipzig
# mit scraperwiki: https://scraperwiki.com
#

# bibliotheken laden
require 'scraperwiki'
require 'nokogiri'   # <- eine bibliothek zum komfortablen arbeiten mit HTML dokumenten

#
# ein paar hilfsfunktionen
#

# extrahiert die daten aus einer einzelnen tabellenzeile
def parse_row(row)
    cells = row.css('td')
    return nil if cells.nil? || cells[1].nil?

    {
        "reference"   => extract_id(cells[0]),
        "title"     => extract_text(cells[1]),
        "originator" => extract_text(cells[3]),
        "date"      => extract_text(cells[4]),
        "paperType"      => extract_text(cells[5]),
        "uri" => "https://ratsinfo.leipzig.de/bi/#{cells[1].css('a').first['href']}"
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

#
# der eigentliche scraper teil
#

# 1. daten laden
html = ScraperWiki.scrape("https://ratsinfo.leipzig.de/bi/vo040.asp?showall=true")
page = Nokogiri::HTML(html)

# 2. zeilen extrahieren
rows = page.css('table.tl1 tbody tr')

data = rows.map do |row|
    next if row.nil?
    p parse_row(row)
end

# 3. Daten speichern

unique_keys = [ 'reference' ]

data.each do |record|
  next unless record && record["reference"]
  ScraperWiki.save_sqlite(unique_keys, record)
end
