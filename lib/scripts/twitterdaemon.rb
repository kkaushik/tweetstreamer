ENV["RAILS_ENV"] ||= "development"

root = File.expand_path(File.join(File.dirname(__FILE__), '..','..'))
puts root
require File.join(root, "config", "environment")
require 'tweetstream'
require 'debugger'
require 'pqueue'
require 'json'

TweetStream.configure do |config|
  config.consumer_key       = ENV["CONSUMER_KEY"]
  config.consumer_secret    = ENV["CONSUMER_SECRET"]
  config.oauth_token        = ENV["OAUTH_TOKEN"]
  config.oauth_token_secret = ENV["OAUTH_TOKEN_SECRET"]
  config.auth_method        = :oauth
end

puts ARGV[2]
term = ARGV[2]
daemon = TweetStream::Daemon.new('tracker', :log_output => true)
@queue = PQueue.new(){ |a,b| a[:retweet_count] < b[:retweet_count] }
puts @queue
daemon.on_inited do
  ActiveRecord::Base.connection.reconnect!
 # ActiveRecord::Base.logger = Logger.new(File.open('log/stream.log', 'w+'))
end
Rails.logger.info("starting daemon for keyword #{term}")




daemon.track(term) do |tweet|
  #Rails.logger.info("WHAT")
  begin
  if tweet.retweeted_status!=nil
    @queue.push({retweet_count: tweet.retweeted_status.retweet_count,
                 text: tweet.text,
                 author: tweet.user.screen_name
                })
    @queue.pop if @queue.size > 10

    File.open(File.join(root, "public", "#{term}.json"), "w") do |f|
      f.write(@queue.to_a.to_json)
    end


  end
  puts tweet.text
  puts tweet.retweeted_status.retweet_count
  rescue Exception => e
    puts e
  end
end

