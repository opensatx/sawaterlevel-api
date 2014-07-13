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

  # Grab the timestamp for when the current level was last updated
  datetime_data = "#{level_data[0]} #{level_data[1]}"
  datetime = Time.parse(datetime_data)
  lastUpdated = datetime.strftime("%FT%T%:z")

  # Get the current stage level from SAWS
  stage_scrape = Nokogiri::HTML(open('http://www.saws.org/'))
  stage_data = stage_scrape.css('#aquifer_tab').text.split.to_a
  stageLevel = stage_data[5].gsub(/[:]/, '').to_f

  # Create the response
  response = { :level => { :recent => level.to_f, :average => average.to_f, :lastUpdated => lastUpdated, }, :stageLevel => stageLevel }.to_json
  response_json = JSON.parse(response)

  # If we're local, puts to command line so we can just see the response
  if self.class.development?
    puts JSON.pretty_generate(response_json)
  end

  # Return json
  content_type :json
  JSON.pretty_generate(response_json)

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