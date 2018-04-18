# frozen_string_literal: true

# My script for 'I analyzed my facebook data and it's story of shyness, loneliness and change'

require 'nokogiri'
require 'axlsx'

# images exchanged
# links exchanged
# percent conversation
# characters written
# words written
# most xD conversation
# most emoji expressive conversation
# messages sent by month
# messages sent by year
# type of texter: night owl, before noon, afternoon
# most used words
# how many times you used xD
# messages during working hours

# my most popular words are almost https://en.wiktionary.org/wiki/Wiktionary:Frequency_lists/Polish_wordlist

# how much friends you gained by year
# how much friends gained during weekday
# friends gained by month
# rank everything

friends = {}
me = Hash.new(0)
my_messages_dates = []
dictionary = Hash.new(0)

def most_popular_polish_words
  @popular_polish_words ||= begin
    File.open('most_popular_polish_words.txt').map do |line|
      line.split(' ')[0].downcase
    end.compact
  end
end

def most_popular_spanish_words
  @popular_spanish_words ||= begin
    File.open('most_popular_spanish_words.txt').map do |line|
      line.split(' ')[0].downcase
    end.compact
  end
end

def most_popular_english_words
  @popular_english_words ||= begin
    File.open('most_popular_english_words.txt').map do |line|
      line.split(' ')[0].downcase
    end.compact
  end
end

catalog = ARGV[0]
user_name = Nokogiri::HTML(File.open("#{catalog}/index.htm")).title.split(' - Profile')[0]

Dir.chdir("#{catalog}/messages") do
  messages_files = Dir.glob('*.html')

  messages_files.each do |file|
    content = File.open(file)

    doc = Nokogiri::HTML(content)
    friend_name = doc.title.split('Conversation with ')[1]

    friends[friend_name] ||= {
      you_count: 0,
      you_characters: 0,
      you_words: 0,
      friend_count: 0,
      friend_characters: 0,
      friend_words: 0,
      total_count: 0,
      you_image_count: 0,
      you_gifs_count: 0,
      you_video_count: 0,
      friend_image_count: 0,
      friend_gifs_count: 0,
      friend_video_count: 0,
    }

    puts "Analyzing conversation with: #{friend_name}"

    conversation = doc.css('.thread').children

    current_message_sender = ''
    conversation.each do |conversation_node|
      if conversation_node.name == 'div' && conversation_node['class'] == 'message'
        current_message_sender = conversation_node.css('span.user').text
        date_info = conversation_node.css('span.meta').text

        if current_message_sender == user_name
          me[:total_message_count] += 1
          friends[friend_name][:you_count] += 1
          friends[friend_name][:total_count] += 1
          my_messages_dates << DateTime.parse(date_info)
        else
          friends[friend_name][:total_count] += 1
          friends[friend_name][:friend_count] += 1
        end
      end

      next unless conversation_node.name == 'p'
      paragraph = conversation_node.text.downcase
      conversation_node.children.each do |image_node|
        if image_node.name == 'img'
          if image_node['src'].include? 'gifs'
            if current_message_sender == user_name
              friends[friend_name][:you_gifs_count] += 1
            else
              friends[friend_name][:friend_gifs_count] += 1
            end
          else
            if current_message_sender == user_name
              friends[friend_name][:you_image_count] += 1
            else
              friends[friend_name][:friend_image_count] += 1
            end
          end
        elsif image_node.name == 'video'
          if current_message_sender == user_name
            friends[friend_name][:you_video_count] += 1
          else
            friends[friend_name][:friend_video_count] += 1
          end
        end
      end

      paragraph = paragraph.delete(',').delete('.')
      paragraph_length = paragraph.length
      paragraph_words = paragraph.split(' ')

      if current_message_sender == user_name
        me[:total_characters] += paragraph_length
        me[:total_words] += paragraph_words.length
        me[:total_xd] += paragraph.scan('xd').length

        paragraph_words.each do |word|
          dictionary[word] += 1
        end

        friends[friend_name][:you_characters] += paragraph_length
        friends[friend_name][:you_words] += paragraph_words.length
      else
        friends[friend_name][:friend_characters] += paragraph_length
        friends[friend_name][:friend_words] += paragraph_words.length
      end
    end
  end
end

ranking = friends.sort_by { |_name, friend| friend[:total_count] }.reverse

package = Axlsx::Package.new
package.workbook.add_worksheet(name: 'Friends ranking') do |sheet|
  sheet.add_row ['Friends ranking']
  sheet.add_row ['Rank', 'Friend name', 'total count', 'your messages count', 'friend messages count', 'your characters count', 'friend characters count', 'your words', 'friend words', 'your images', 'friend images', 'your gifs', 'friend gifs', 'your videos', 'friend videos']
  rank = 1
  ranking.each do |friend_name, friend_data|
    sheet.add_row [rank, friend_name,
                   friend_data[:total_count], friend_data[:you_count],
                   friend_data[:friend_count], friend_data[:you_characters],
                   friend_data[:friend_characters], friend_data[:you_words],
                   friend_data[:friend_words], friend_data[:you_image_count],
                   friend_data[:friend_image_count], friend_data[:you_gifs_count],
                   friend_data[:friend_gifs_count], friend_data[:you_video_count],
                   friend_data[:friend_video_count]]
    rank += 1
  end
end

# analyze message patterns when messages are sent
package.workbook.add_worksheet(name: 'My message statistics') do |sheet|
  sheet.add_row ['My message statistics']
  sheet.add_row ["You sent in total #{me[:total_message_count]} messages"]
  sheet.add_row ["You used #{me[:total_characters]} characters in total"]
  sheet.add_row ["You also used #{me[:total_words]} words in total"]
  sheet.add_row ["You also happened to use xD #{me[:total_xd]} times"]
  sheet.add_row ['']

  by_month = Hash.new(0)
  by_year = Hash.new(0)
  by_day_of_week = Hash.new(0)
  by_weekend = Hash.new(0)
  by_date = Hash.new(0)
  by_hour = Hash.new(0)
  by_year_hour = Hash.new(0)

  my_messages_dates.each do |date|
    by_month[date.strftime('%B')] += 1
    by_year[date.year] += 1
    by_day_of_week[date.strftime('%A')] += 1

    if date.friday? || date.saturday? || date.sunday?
      by_weekend[:weekend] += 1
    else
      by_weekend[:working] += 1
    end

    by_date[date.strftime('%F')] += 1
    by_hour[date.hour] += 1
    by_year_hour["#{date.year} - #{date.hour}"] += 1
  end

  sheet.add_row ['Messaging by month']
  sheet.add_row ['Month', 'number of messages']
  by_month.sort_by { |_month, count| count }.each do |month, count|
    sheet.add_row [month, count]
  end

  sheet.add_row ['Messaging by year']
  sheet.add_row ['Year', 'number of messages']
  by_year.sort_by { |year, _count| year }.each do |year, count|
    sheet.add_row [year, count]
  end

  sheet.add_row ['Messaging by day of week']
  sheet.add_row ['Day of week', 'number of messages']
  by_day_of_week.sort_by { |_day, count| count }.reverse.each do |day, count|
    sheet.add_row [day, count]
  end

  sheet.add_row ['Messaging on week days vs. weekend']
  sheet.add_row ['Type of day', 'number of messages']
  by_weekend.each do |type, count|
    sheet.add_row [type, count]
  end

  sheet.add_row ['Breakdown of messages by hour']
  sheet.add_row ['Hour', 'number of messages']
  by_hour.sort_by { |hour, _count| hour }.each do |hour, count|
    sheet.add_row [hour, count]
  end

  sheet.add_row ['Breakdown of messages by hour and year']
  sheet.add_row ['Year and hour', 'number of messages']
  by_year_hour.sort_by { |year_hour, _count| y, h = year_hour.split(' - '); "#{y}0".to_i + h.to_i }.each do |year_hour, count|
    sheet.add_row [year_hour, count]
  end

  sheet.add_row ['Most busy messaging days']
  sheet.add_row ['Date', 'number of messages']
  by_date.sort_by { |_date, count| count }.reverse.each do |date, count|
    sheet.add_row [date, count]
  end
end

package.workbook.add_worksheet(name: 'Vocabulary statistics') do |sheet|
  sheet.add_row ['Vocabulary statistics']
  sheet.add_row ["You used #{dictionary.length} unique words and #{me[:total_words]} words in total"]

  most_popular_spanish_words.each do |word|
    dictionary.delete(word)
  end
  
  most_popular_english_words.each do |word|
    dictionary.delete(word)
  end

  sheet.add_row ['This are cleaned results without most common english words']
  sheet.add_row %w[Rank Word Occurences]

  words_ranked = dictionary.sort_by { |_word, count| count }.reverse[0..999]
  rank = 1
  words_ranked.each do |word, count|
    sheet.add_row [rank, word, count]
    rank += 1
  end
end

# contact info data
# how much facebook archived
Dir.chdir("#{catalog}/html/") do
  content = File.open('contact_info.htm').read
  doc = Nokogiri::HTML(content)

  contacts_rows = doc.css('div.contents tr')

  contacts = contacts_rows.map do |contact|
    text = contact.text
    if text == 'NameContacts'
    else
      contact_info = text.split('contact: ')
      [String(contact_info[0]), contact_info[1..3].join(' ')]
    end
  end.compact.uniq

  package.workbook.add_worksheet(name: 'Contact list') do |sheet|
    sheet.add_row ['Contact list']
    sheet.add_row ["Facebook imported #{contacts.length} of your contacts"]
    sheet.add_row ['Name', 'Phone number']
    contacts.sort_by { |contact_name, _info| contact_name }.each do |contact_name, contact_num|
      sheet.add_row [contact_name, contact_num]
    end
  end
end

# analyze making of friends
friends_dates = []
Dir.chdir("#{catalog}/html/") do
  content = File.open('friends.htm').read
  doc = Nokogiri::HTML(content)
  friends_list = doc.css('div.contents > ul')[0].css('li')

  friends_list.each do |friend_element|
    friend_with_email = friend_element.text.match(/(.*)\s\((.*)\)\s\((.*)\)/)
    if friend_with_email
      name, date_added = friend_with_email.captures
    else
      name, date_added = friend_element.text.match(/(.*)\s\((.*)\)/).captures
    end
    date = if date_added == 'Today'
             Date.today
           elsif date_added == 'Yesterday'
             Date.today.prev_day
           else
             DateTime.parse(date_added)
           end

    friends_dates << date
  end
end

by_year = Hash.new(0)
by_week_day = Hash.new(0)
by_day = Hash.new(0)
by_month = Hash.new(0)
by_month_and_year = Hash.new(0)
by_weekend = Hash.new(0)
by_weekend_and_year = Hash.new(0)
by_week_and_year = Hash.new(0)

friends_dates.each do |date|
  by_year[date.year] += 1
  by_week_day[date.strftime('%A')] += 1
  by_day[date.strftime('%F')] += 1
  by_month[date.strftime('%B')] += 1
  by_month_and_year[date.strftime('%B - %Y')] += 1
  by_week_and_year["week #{date.strftime('%V')} of #{date.year}"] += 1

  if date.friday? || date.saturday? || date.sunday?
    by_weekend[:weekend] += 1
  else
    by_weekend[:working] += 1
  end
end

package.workbook.add_worksheet(name: 'Making friends') do |sheet|
  sheet.add_row ['Making friends']
  sheet.add_row ['']
  sheet.add_row ['Making friends by year']
  sheet.add_row ['Year', 'Number of friends added']

  by_year.sort_by { |year, _count| year }.each do |year, count|
    sheet.add_row [year, count]
  end

  sheet.add_row ['Making friends by week day']
  sheet.add_row ['Day of week', 'Number of friends added']

  by_week_day.sort_by { |_day, count| count }.reverse.each do |day, count|
    sheet.add_row [day, count]
  end

  sheet.add_row ['Making friends by month']
  sheet.add_row ['Month', 'Number of friends added']

  by_month.sort_by { |_month, count| count }.reverse.each do |month, count|
    sheet.add_row [month, count]
  end

  sheet.add_row ['Making friends on weekend vs. working days']
  sheet.add_row ['Working day or weekend', 'Number of friends added']
  by_weekend.each do |type_of_day, count|
    sheet.add_row [type_of_day.to_s, count]
  end

  sheet.add_row ['Most busy weeks for making friends (week number and year)']
  sheet.add_row ['Week and year', 'Number of friends added']

  by_week_and_year.sort_by { |_week_year, count| count }.reverse.each do |week_year, count|
    sheet.add_row [week_year, count]
  end

  sheet.add_row ['Most busy month-year by friends added']
  sheet.add_row ['Month year', 'Number of friends added']
  by_month_and_year.sort_by { |_month_year, count| count }.reverse.each do |month_year, count|
    sheet.add_row [month_year, count]
  end

  sheet.add_row ['Most busy making friends days']
  sheet.add_row ['Day', 'Number of friends added']

  by_day.sort_by { |_day, count| count }.reverse.each do |day, count|
    sheet.add_row [day, count]
  end
end

package.serialize('facebook_analysis.xlsx')
