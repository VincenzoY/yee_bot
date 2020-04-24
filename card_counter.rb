
# frozen_string_literal: true

# Users can add a card number to keep track of how many cards they are at in Anki

require 'discordrb'
require 'sqlite3'

# This statement creates a bot with the specified token and application ID. After this line, you can add events to the
# created bot, and eventually run it.
#
# If you don't yet have a token to put in here, you will need to create a bot account here:
#   https://discordapp.com/developers/applications
# If you're wondering about what redirect URIs and RPC origins, you can ignore those for now. If that doesn't satisfy
# you, look here: https://github.com/discordrb/discordrb/wiki/Redirect-URIs-and-RPC-origins
# After creating the bot, simply copy the token (*not* the OAuth2 secret) and put it into the
# respective place.

token = "MzUxODYxNjk5NTY2ODk1MTA1.XqMYqA.eslgkHd_aDohrWzcwoY7BggOuQg"

bot = Discordrb::Commands::CommandBot.new token: token, prefix: ';'

# Invite url

puts "This bot's invite URL is #{bot.invite_url}."
puts 'Click on it to invite it to your server.'

# Commands

bot.command :user do |event|
    event.user.id
end

bot.command :help do |event|
    event << "Commands"
    event << "Subtract cards: ;subtract [kanji/vocab] [number]"
    event << "Add cards: ;add [kanji/vocab] [number]"
    event << "Total cards: ;cards [@user/user id/(empty)]"
end

bot.command :add do |event, cardType, int|
    if Integer(int)
        if cardType.downcase == "kanji" || cardType.downcase == "vocab" || cardType.downcase == "vocabulary"
            add_to_database(event.user.id, cardType, Integer(int))
            event.respond "Success! Added #{int} cards to #{cardType}"
        else
            event.respond "Sorry, that's not a valid command. The format is ;add [card type] [integer]. Valid card types are Kanji or Vocab"
        end
    else
        event.respond "#{int} is not a valid number."
    end
end

bot.command :subtract do |event, cardType, int|
    if Integer(int).is_a?(Integer)
        if cardType.downcase == "kanji" || cardType.downcase == "vocab" || cardType.downcase == "vocabulary"
            subtract_database(event.user.id, cardType, Integer(int))
            event.respond "Success! Subtracted #{int} cards to #{cardType}"
        else
            event.respond "Sorry, that's not a valid command. The format is ;subtract [card type] [integer]. Valid card types are Kanji or Vocab"
        end
    else
        event.respond "#{int} is not a valid number."
    end
end

bot.message(content: 'Ping!') do |event|
  event.respond 'Pong!'
end

bot.command :cards do |event, name=""|
    begin
        db = SQLite3::Database.open "card_counter.db"
        db.results_as_hash = true
        if name[0..1] == "<@"
            name = name[3..20].to_i
        elsif name == ""
            name = event.user.id
        elsif name.to_i.is_a?(Integer) && name.length == 18
        else
            event.respond "That is not a valid command"
            break
        end
        db.execute ("SELECT kanji, vocab FROM stats WHERE userId=#{name}") do |row|
            event.respond "#{bot.user(name).name.capitalize} has finished #{row["kanji"]} Kanji cards and #{row["vocab"]} Vocab cards"
        end
    ensure
        db.close if db
    end
end

#testing embeds

bot.command :test do |e|
e.channel.send_embed do |embed|
    embed.title = "Vyee"
    embed.description = "-"
    embed.color = "d60000"
    embed.thumbnail = Discordrb::Webhooks::EmbedThumbnail.new(url: "https://cdn.discordapp.com/avatars/322845778127224832/a7b64895365176e9fe98be98dac0d72b.webp")
    fields = [Discordrb::Webhooks::EmbedField.new({name: "Kanji", value: "123", inline: true}),
                Discordrb::Webhooks::EmbedField.new({name: "Vocab", value: "789", inline: true}),
                Discordrb::Webhooks::EmbedField.new({name: "Total", value: "456", inline: true})]
    embed.fields = fields
    embed.footer = Discordrb::Webhooks::EmbedFooter.new(text: "Created by Vincent Y")
end
end

# database

db = SQLite3::Database.open "card_counter.db"
db.results_as_hash = true
db.execute "CREATE TABLE IF NOT EXISTS stats(userId varchar(20), kanji INT, vocab INT)"

def add_to_database(userId, cardType, int)
    begin
        db = SQLite3::Database.open "card_counter.db"
        previous = db.get_first_value "SELECT #{cardType} FROM stats WHERE userId=?", userId
        db.execute "UPDATE stats SET #{cardType}=? WHERE userId=?", int+previous, userId
    rescue => exception
        db.execute "INSERT INTO stats (userId, kanji, vocab) VALUES (?, ?, ?)", userId, 0, 0
        add_to_database(userId, cardType, int)
    ensure 
        db.close if db
    end
end

def subtract_database(userId, cardType, int)
    begin
        db = SQLite3::Database.open "card_counter.db"
        previous = db.get_first_value "SELECT #{cardType} FROM stats WHERE userId=?", userId
        db.execute "UPDATE stats SET #{cardType}=? WHERE userId=?", Integer(previous-int), userId
    ensure 
        db.close if db
    end
end

bot.run
