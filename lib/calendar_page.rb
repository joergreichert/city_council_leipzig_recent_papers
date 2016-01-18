require 'nokogiri'
require 'page'

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
