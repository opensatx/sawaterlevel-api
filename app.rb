require 'sinatra'
require 'nokogiri'
require 'open-uri'
require 'json'
require 'dalli'
require 'memcachier'
require 'httparty'
require 'sqlite3'


get '/level' do

  # Set up the local db connection
  db = SQLite3::Database.new('db.sqlite3')

  # Create the table if needed
  db.execute("CREATE TABLE IF NOT EXISTS Responses (ID INTEGER PRIMARY KEY, RecentLevel REAL, AverageLevel REAL, LastUpdated TEXT, StageLevel INTEGER, IrrigationAllowed NUMERIC)")

  # Get the 10-day average
  # average_scrape = Nokogiri::HTML(open('http://www.edwardsaquifer.org/data/historic.php')) # Get the data
  # average_data = average_scrape.xpath('//td/text()').to_a  # Just grab the numbers
  # average = average_data[4].to_s # Take the 10-day average, make it a string

  if self.class.development?
    dalli = Dalli::Client.new('localhost:11211', { :namespace => "sawaterlevel",
      :compress => true,  :expires_in => 10 * 60})
  else
    dalli = Dalli::Client.new(ENV["MEMCACHIER_SERVERS"].split(","),
                    {:username => ENV["MEMCACHIER_USERNAME"],
                     :password => ENV["MEMCACHIER_PASSWORD"],
                     :namespace => "sawaterlevel",
                     :compress => true,
                     :expires_in => 10 * 60
                     })
  end

  response = dalli.get('tenday')

  unless response
    average_scrape = Nokogiri::HTML(HTTParty.get('http://www.edwardsaquifer.org/'))
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

    # Let's build a sample irrigation level
    if stageLevel.eql?(3) || stageLevel > 3
      irrigationAllowed = "undefined"
    else
      irrigationAllowed = true
    end

    # Create the response
    response = { :level => { :recent => level.to_f.round(2), :average => average.to_f.round(2), :lastUpdated => lastUpdated, }, :stageLevel => stageLevel, :irrigationAllowed => irrigationAllowed }.to_json

    dalli.set('tenday', response)
  end

  response_json = JSON.parse(response)

  # If we're local, puts to command line so we can just see the response
  if self.class.development?
    puts JSON.pretty_generate(response_json)
  end

  # Store response in DB if we don't already have it
  unless db.execute("SELECT ID FROM Responses WHERE LastUpdated = ?", response_json["level"]["lastUpdated"]).length > 0
    db.execute("INSERT INTO Responses (RecentLevel, AverageLevel, LastUpdated, StageLevel, IrrigationAllowed) VALUES (?, ?, ?, ?, ?)", 
      response_json["level"]["recent"], 
      response_json["level"]["average"], 
      response_json["level"]["lastUpdated"], 
      response_json["stageLevel"], 
      response_json["irrigationAllowed"].to_s
    )	  
  end	

  # Return json
  content_type :json
  JSON.pretty_generate(response_json)

end

get '/' do
  erb :index
end
