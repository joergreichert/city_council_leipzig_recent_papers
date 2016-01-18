require 'minitest/autorun'
require 'calendar_page'
require 'fixture_fetcher'

class TestCalendarPage < Minitest::Test

  def test_expand_link
    page = CalendarPage.new('https://ratsinfo.leipzig.de/bi/si010_e.asp?PA=0&MM=11&YY=2015')
    expected = 'https://ratsinfo.leipzig.de/bi/to010.asp?SILFDNR=1000327'
    assert_equal(expected, page.expand_link('to010.asp?SILFDNR=1000327'))
  end

  def test_meetings
    uri = 'https://ratsinfo.leipzig.de/bi/si010_e.asp?PA=0&MM=11&YY=2015'
    meetings = CalendarPage.new(uri, fetcher: FixtureFetcher).meetings
    expected_meetings = [
      {
        id: 'https://ratsinfo.leipzig.de/bi/to010.asp?SILFDNR=1002144',
        type: 'oparl:Meeting',
        name: 'Ratsversammlung',
      },
      {
        id: 'https://ratsinfo.leipzig.de/bi/to010.asp?SILFDNR=1000327',
        type: 'oparl:Meeting',
        name: 'Ratsversammlung',
      }]
    assert_equal(expected_meetings, meetings)
  end
end
