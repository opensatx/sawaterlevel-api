require 'sinatra'
require 'nokogiri'
require 'open-uri'
require 'json'

get '/level' do

  # Get the 10-day average
  average_scrape = Nokogiri::HTML(open('http://www.edwardsaquifer.org/data/historic.php')) # Get the data
  average_data = average_scrape.xpath('//td/text()').to_a  # Just grab the numbers
  average = average_data[4].to_s # Take the 10-day average, make it a string

  # Get the current level
  level_scrape = Nokogiri::HTML(open('http://www.edwardsaquifer.org/data/j17_live.php')) # Get the data
  level_data = level_scrape.xpath('//td/text()').to_a
  level = level_data[2].to_s

  # Grab the timestamp for the current level
  datetime_data = "#{level_data[0]} #{level_data[1]}"
  datetime = Time.parse(datetime_data)
  timestamp = datetime.strftime("%FT%T%:z")

  # Return json
  content_type :json
  {:level => {:timestamp => timestamp, :level => level.to_f, :average => average.to_f}}.to_json

end

get '/' do

    "This is a simple api exposing scraped SAWS data.<br />Data endpoint: <a href='/level'>/level</a>"
    
end