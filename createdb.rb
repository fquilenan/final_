# Set up for the application and database. DO NOT CHANGE. #############################
require "sequel"                                                                      #
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB ||= Sequel.connect(connection_string)                                              #
#######################################################################################

# Database schema - this should reflect your domain model
DB.create_table! :events do
  primary_key :id
  String :title
  String :description, text: true
  String :date
  String :location
  String :sport
end
DB.create_table! :rsvps do
  primary_key :id
  foreign_key :event_id
  foreign_key :user_id
  Boolean :going
  String :comments, text: true
end
DB.create_table! :users do
  primary_key :id
  String :name
  String :email
  String :password
end

# Insert initial (seed) data
events_table = DB.from(:events)

events_table.insert(title: "Soccer match 7x7", 
                    description: "We are a group of friends looking for friendly soccer matches!",
                    date: "June 21",
                    location: "Kellogg Global Hub",
                    sport: "Soccer")

events_table.insert(title: "Tennis training session", 
                    description: "If you want to improve your tennis skills and your a begginer, you're all welcome!",
                    date: "July 4",
                    location: "Evanston, Illinois",
                    sport: "Tennis")

events_table.insert(title: "Bike ride", 
                    description: "We meet every Sunday morning and make a 30 miles ride, come and join us!",
                    date: "Sunday, March 15th, at 9:00",
                    location: "Target, Evanston",
                    sport: "Bike")
