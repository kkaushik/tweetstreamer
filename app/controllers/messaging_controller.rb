#class MessagingController < ApplicationController
#  include ActionController::Live
#
#  def send_message
#    response.headers['Content-Type'] = 'text/event-stream'
#    10.times {
#      response.stream.write "This is a test Messagen"
#      sleep 1
#    }
#    response.stream.close
#  end
#end


require 'serverside/sse'
require 'daemons'

class MessagingController < ApplicationController
  include ActionController::Live

  def index
    response.headers['Content-Type'] = 'text/event-stream'
    sse = ServerSide::SSE.new(response.stream)
    term = params[:filter]
    root = File.expand_path(File.join(File.dirname(__FILE__), '..','..'))

    filename= File.join(root, "public", "#{term}.json")
    filter_ob = FilterData.find_by_filter(term)
    if filter_ob.present?
      File.open(filename, "w") do |f|
        f.write(filter_ob.filter_data)
      end
    else
      FilterData.create!(:filter => term)
      File.open(filename, 'w') {|f| f.write("{}") }
    end

    system("ruby #{File.join(Rails.root, 'lib','scripts','twitterdaemon.rb')} restart -- #{term}")
    begin
      loop do
        data = IO.read(filename)
        sse.write({ :message => JSON.parse( data) })
        FilterData.where(:filter => term).first.update_columns(filter_data: data)
        sleep 1
      end
    rescue IOError
    rescue JSON::ParserError

    ensure
      sse.close
      File.delete(filename) if File.exist?(filename)
    end
  end

end
