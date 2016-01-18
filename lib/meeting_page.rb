require 'nokogiri'
require 'page'
require 'pry'

class MeetingPage < Page

  def meeting
    time = Time.parse(doc.css("table.tk1 table.tk1 td:contains('Datum') ~ td").first.text)
    start_value, end_value = doc.css("table.tk1 table.tk1 td:contains('Zeit') ~ td").first.text.split(" - ")
    {
      id: uri,
      type: 'oparl:Meeting',
      name: doc.css("table.tk1 table.tk1 td:contains('Bezeichnung') ~ td").first.text,
      start: Time.parse(start_value, time).iso8601,
      state: doc.css("table.tk1 table.tk1 td:contains('Status') ~ td").first.text,
      end: Time.parse(end_value, time).iso8601,
    }
  end
end
