require "sinatra" 
require "data_mapper"
require "json"
require "sinatra/contrib"
require "jsonify"

set :views, settings.root + '/views'

class User  
    include DataMapper::Resource
    property :username,     String, required: true, :key => true
    property :created_at,   DateTime

    def username= new_username
        super new_username.downcase
    end

    has n, :moments
end

# Moment won't be granted an id when properties are set to decimal

class Moment
    include DataMapper::Resource
    property :id,           Serial, :key => true
    property :timestamp,    Integer, required: true
    property :lat,          Float, required: true
    property :lon,          Float, required: true
    property :transcription,String, :length => 500, required: true 
    property :created_at,   DateTime
    belongs_to :user
end

# As of now, DataMapper is not used for anything. These are just placeholders.
configure :development do
    DataMapper.setup(:default, ENV['DATABASE_URL'] || "postgres://localhost/steno")
    DataMapper.auto_upgrade!
    #DataMapper.auto_migrate! # wipes everything
    DataMapper.finalize
end 

configure :production do
    require 'newrelic_rpm'
    DataMapper.setup(:default, ENV['DATABASE_URL'] || "postgres://localhost/steno")
    DataMapper.auto_upgrade!
    DataMapper.finalize

    # unless tring to wipe db schema don not run .auto_upgrade in production
end



get "/" do
    @title = "Steno"
    set :erb, :layout => false
    erb :index
end

get "/changelog" do
    @title = "Steno - Changelog"
    set :erb, :layout => false
    erb :changelog
end

# API spec has been outlined here http://www.stypi.com/tedlee/Steno/api_spec.json

post "/users" do

    # Creates a data hash
    data = JSON.parse(request.body.read)
 
    # Gets username
    username = data['user']
    #@user = User.get username
    @user = User.first(:username => username) 
    

    if @user
        puts @user.username
        puts @user.moments
    else
        User.create(:username => username, :created_at => Time.now)
        @user = User.first(:username => username) 
        puts @user
    end

    timestamp = 0
    lat = 0
    lon = 0
    transcription = ""

    data['steno_blobs'].each do |blob|

        # Gets blob timestamp
        timestamp = blob["blob"]["timestamp"]

        # Gets blob latitude
        lat = blob["blob"]["lat"]

        # Gets blob longitude
        lon = blob["blob"]["lon"]

        # Get best ranked transcription result
        transcription = blob["blob"]["transcription"][0]

    end

    Moment.create(:timestamp => timestamp, :lat => lat, :lon => lon, :transcription => transcription, :created_at => Time.now, :user_username => @user.username)
    json "username" => username, "timestamp" => timestamp, "lat" => lat, "lon" => lon, "transcription" => transcription
end

# generates the webpage
get "/:username" do
    @user = User.get params[:username]

    if @user
        @title = "The Steno of #{@user.username}"
        erb :user
    else
        "That user doesn't exist yet :("
    end
end

# return API call
get "/api/users/:username" do
    @user = User.get params[:username]
    #@user.moments.reverse.each do |moment|

    if @user
        # JSON reponse containing all user moments

        content_type :json
        response = Jsonify::Builder.new(:format => :pretty)
        response.moments(@user.moments) do |moment|
            response.timestamp moment.timestamp
            response.transcription moment.transcription
            response.lat moment.lat
            response.lon moment.lon
        end

        response.compile!
    else
        "That user doesn't exist yet :("
    end
end

not_found do  
    halt 404, "No page for you."
end