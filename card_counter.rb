
# frozen_string_literal: true

# Users can add a card number to keep track of how many cards they are at in Anki

require 'discordrb'
require 'database.rb'

# This statement creates a bot with the specified token and application ID. After this line, you can add events to the
# created bot, and eventually run it.
#
# If you don't yet have a token to put in here, you will need to create a bot account here:
#   https://discordapp.com/developers/applications
# If you're wondering about what redirect URIs and RPC origins, you can ignore those for now. If that doesn't satisfy
# you, look here: https://github.com/discordrb/discordrb/wiki/Redirect-URIs-and-RPC-origins
# After creating the bot, simply copy the token (*not* the OAuth2 secret) and put it into the
# respective place.

bot = Discordrb::Bot.new token: 'MzUxODYxNjk5NTY2ODk1MTA1.XqMYqA.eslgkHd_aDohrWzcwoY7BggOuQg', prefix: ';'

# Invite url

puts "This bot's invite URL is #{bot.invite_url}."
puts 'Click on it to invite it to your server.'

# Commands

bot.command :user do |event|
    event.user.name
end


bot.message(content: 'Ping!') do |event|
  event.respond 'Pong!'
end

bot.run