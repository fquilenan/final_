# Set up for the application and database. DO NOT CHANGE. #############################
require "sinatra"  
require "sinatra/cookies"                                                             #
require "sinatra/reloader" if development?                                            #
require "sequel"                                                                      #
require "logger"                                                                      #
require "bcrypt"                                                                      #
require "twilio-ruby"   
require "geocoder"                                                              #
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB ||= Sequel.connect(connection_string)                                              #
DB.loggers << Logger.new($stdout) unless DB.loggers.size > 0                          #
def view(template); erb template.to_sym; end                                          #
use Rack::Session::Cookie, key: 'rack.session', path: '/', secret: 'secret'           #
before { puts; puts "--------------- NEW REQUEST ---------------"; puts }             #
after { puts; }                                                                       #
#######################################################################################

events_table = DB.from(:events)
rsvps_table = DB.from(:rsvps)
users_table = DB.from(:users)
account_sid = ENV["TWILIO_ACCOUNT_SID"]
auth_token = ENV["TWILIO_AUTH_TOKEN"]



client = Twilio::REST::Client.new(account_sid, auth_token)



before do
    @current_user = users_table.where(id: session["user_id"]).to_a[0]
end

get "/" do
    puts events_table.all
     @events = events_table.all.to_a
    view "landing"
end

get "/events" do
     puts events_table.all
     @events = events_table.all.to_a
    view "events"
end

get "/events/new" do
    view "new_event"
end
post "/events/create" do
    puts params
    events_table.insert(title: params["title"], 
                        description: params["description"], 
                        date: params["date"], 
                        location: params["location"])
    view "create_event"
end



get "/events/:id" do
    @event = events_table.where(id: params[:id]).to_a[0]
    @rsvps = rsvps_table.where(event_id: @event[:id])
    @going_count = rsvps_table.where(event_id: @event[:id], going: true).count
    @users_table = users_table
    
    results = Geocoder.search(@event[:location])
    lat_lng = results.first.coordinates 
    @lat_long = "#{lat_lng[0]}, #{lat_lng[1]}" 
    
    view "event"
end





get "/events/:id/rsvps/new" do
    @event = events_table.where(id: params[:id]).to_a[0]
    view "new_rsvp"
end

get "/events/:id/rsvps/create" do
    puts params
    @event = events_table.where(id: params["id"]).to_a[0]
    rsvps_table.insert(event_id: params["id"],
                       user_id: session["user_id"],
                       going: params["going"],
                       comments: params["comments"])


    title = @event[:title]
    date = @event[:date]
    location = @event[:location]
    client.messages.create(
        from: "+12029328591", 
        to: "+12247306141",
        body: "Your reservation for #{title} is now confirmed. Remember, on #{date} at #{location}, see you there!" 
        )
    view "create_rsvp"
end

get "/users/new" do
    view "new_user"
end

post "/users/create" do
    puts params
    hashed_password = BCrypt::Password.create(params["password"])
    users_table.insert(name: params["name"], email: params["email"], password: hashed_password)
    
    # Trying to personalize msg
    #name = @users_table["name"]
    #{name}

    client.messages.create(
        from: "+12029328591", 
        to: "+12247306141",
        body: "Thanks for signing up! Now you can explore all the events we have for you."
        )
    view "create_user"
end

get "/logins/new" do
    view "new_login"
end

post "/logins/create" do
    user = users_table.where(email: params["email"]).to_a[0]
    puts BCrypt::Password::new(user[:password])
    if user && BCrypt::Password::new(user[:password]) == params["password"]
        session["user_id"] = user[:id]
        @current_user = user
        view "create_login"
    else
        view "create_login_failed"
    end
end

get "/logout" do
    session["user_id"] = nil
    @current_user = nil
    view "logout"
end




