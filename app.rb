require 'sinatra'
require 'nokogiri'
require 'open-uri'
require 'json'

get '/level' do

  # Get the 10-day average
  # average_scrape = Nokogiri::HTML(open('http://www.edwardsaquifer.org/data/historic.php')) # Get the data
  # average_data = average_scrape.xpath('//td/text()').to_a  # Just grab the numbers
  # average = average_data[4].to_s # Take the 10-day average, make it a string

  average_scrape = Nokogiri::HTML(open('http://www.edwardsaquifer.org/'))
  average_data = average_scrape.xpath('//td/text()').to_a
  average_with_char = average_data[7].to_s.delete('*')
  average = average_with_char.to_f

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
  stageLevel = stage_data[5].gsub(/[:]/, '').to_i

  # Create the response
  response = { :level => { :recent => level.to_f.round(2), :average => average.to_f.round(2), :lastUpdated => lastUpdated, }, :stageLevel => stageLevel }.to_json
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

    erb :index
    
end