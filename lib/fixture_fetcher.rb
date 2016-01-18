class FixtureFetcher
  require 'base64'

  def self.fetch(uri)
    filename = Base64.strict_encode64(uri)
    File.read("#{__dir__}/../fixtures/#{filename}")
  end
end
