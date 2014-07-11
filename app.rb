require 'sinatra'
require 'nokogiri'
require 'open-uri'
require 'json'

get '/level' do

  # Grab the data we need
  historic_data = Nokogiri::HTML(open('http://www.edwardsaquifer.org/data/historic.php'))

  # Just grab the numbers
  data = historic_data.xpath('//td/text()').to_a

  # Pull out our specific numbers
  level = data[0].to_s
  average = data[4].to_s

  # Generate timestamp
  timestamp = Time.now.strftime("%FT%T%:z") # date and time of day

  # Return json
  content_type :json
  {:level => {:timestamp => timestamp, :level => level.to_f, :average => average.to_f}}.to_json


end

get '/' do
    "This is a simple api exposing scraped SAWS data.<br />Data endpoint: <a href='/level'>/level</a>"
end