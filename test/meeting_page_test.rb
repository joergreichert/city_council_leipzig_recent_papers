require 'minitest/autorun'
require 'meeting_page'
require 'fixture_fetcher'

class TestMeetingPage < Minitest::Test
  def test_meeting
    uri = 'https://ratsinfo.leipzig.de/bi/to010.asp?SILFDNR=1002144'
    meeting = MeetingPage.new(uri, fetcher: FixtureFetcher).meeting
    expected_meeting = {
      id: 'https://ratsinfo.leipzig.de/bi/to010.asp?SILFDNR=1002144',
      type: 'oparl:Meeting',
      name: 'Ratsversammlung',
      # room: 'Neues Rathaus, Sitzungssaal des Stadtrates',
      # street_address: 'Martin-Luther-Ring 4-6',
      # postal_code: '04109',
      # locality: 'Neues Rathaus',
      start: '2015-11-11T18:00:00+01:00',
      state: 'öffentlich/nichtöffentlich',
      end: '2015-11-11T19:30:00+01:00'
    }
    assert_equal(expected_meeting, meeting)
  end
end
