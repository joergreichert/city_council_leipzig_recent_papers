require 'rubygems'
require 'scraperwiki'
require 'nokogiri'
require 'html_to_plain_text'

ScraperWiki.config = { db: 'data.sqlite' }

@retries = []

def will_retry(method_name, *arguments)
  @retries.push({method: method_name, arguments: arguments})
end

def download(uri)
  ScraperWiki.scrape(uri)
end

def scrape(uri)
  begin
    html = download(uri)
  rescue StandardError => e
    puts "Could not load #{uri.inspect}"
    puts e
    return false
  end
  yield html
end

def scrape_detail_page(record, uri, retry_if_failed: true)
  if scrape(uri) { |html|
      page = Nokogiri::HTML(html)
      record[:content] = extract_content(page)
      record[:resolution] = extract_resolution(page)
      record[:related_paper_id] = extract_related_paper(page)
      record[:scraped_at] = Time.now
      # Daten speichern
      ScraperWiki.save_sqlite([:id], record, 'data')
    }
  elsif retry_if_failed
    will_retry(:scrape_detail_page, record, uri, retry_if_failed: false)
  end
end

def expand_uri(path)
  "https://ratsinfo.leipzig.de/bi/#{path}"
end

# extrahiert die daten aus einer einzelnen tabellenzeile
def parse_row(row)
  cells = row.css('td')
  return nil if cells.nil? || cells[1].nil?
  name_text = extract_text(cells[1]).match(/([-\w\/]+)(.*)/)
  url = expand_uri(cells[1].css('a').first['href'])
  {
    id: url,
    url: url,
    reference: name_text[1],
    name: name_text[2][/\w.*/],
    published_at: Date.parse(extract_text(cells[4])),
    paper_type: extract_text(cells[5]),
    originator: extract_text(cells[3]),
  }
end

# extrahiert die VOLFDNR aus einer tabellenzelle
def extract_id(cell)
  return nil if cell.nil?
  input   = cell.css('input[@name="VOLFDNR"]').first
  return nil if input.nil?
  volfdnr = input["value"]
end

def extract_word(text)
  text.match(/(\A\W*)(.+)(\W*$)/)[2]
end

# extrahiert den text aus den tabellenzellen
def extract_text(cell)
  return nil if cell.nil?
  cell.text
end

def html_to_plain_text(node)
  return unless node
  HtmlToPlainText.plain_text(node.to_s)
end

def extract_content(page)
  html = page.css('a[name="allrisSV"] ~ div:first-of-type').first
  html_to_plain_text(html)
end

def extract_resolution(page)
  html = page.css('a[name="allrisBV"] ~ div:first-of-type').first
  html_to_plain_text(html)
end

def extract_related_paper(page)
  page.css('.ko1 td:contains("Bezüglich:") ~ td a').map { |a|
    expand_uri(a["href"])
  }.join(',')
end

# Übersicht-Seite laden und Zeilen extrahieren
uri = "https://ratsinfo.leipzig.de/bi/vo040.asp?showall=true"
puts "Loading index page #{uri}"
page = Nokogiri::HTML(download(uri))
records = page.css('table.tl1 tbody tr').map do |row|
  next if row.nil?
  parse_row(row)
end

# Detail-Seite laden und Text speichern
records.each_with_index do |record, i|
  next unless record
  uri = record[:url]
  puts "Loading details page #{i+1} of #{records.length} #{uri}"
  scrape_detail_page(record, uri)
end

puts "Retrying #{@retries.length} failed…"
sleep 5
@retries.each do |task|
  send(task[:method], *task[:arguments])
end
