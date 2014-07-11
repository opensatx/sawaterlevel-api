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

    "<h2>This is a simple API that scrapes level data San Antonio's Edwards Aquifer Authority.</h2>
    Data endpoint: <a href='/level'>/level</a>
    <br />
    <br />timestamp is the time the <a href='http://www.edwardsaquifer.org/data/j17_live.php'>most current level was updated</a> (every 15 minutes)
    <br />level is the current <a href='http://www.edwardsaquifer.org/aquifer-data-and-maps/j17-data'>J17 aquifer level</a>
    <br />average is the <a href='http://www.edwardsaquifer.org/aquifer-data-and-maps/historical-data'>J17 aquifer 10-day average level</a>
    <br />
    <br />Fork me on Github: <a href='https://github.com/opensatx/sawaterlevel-api'>opensatx/sawaterlevel-api</a>
    <br />Data scraped from: <a href=''>Edwards Aquifer Authority</a> (thanks!)"
    
end