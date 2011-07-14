require 'rubygems'
require 'eventmachine'
require 'json'

module TasksDispatcher
  
  def initialize
    @tasks = {}
  end

  def receive_data(data)
    json = JSON.parse(data)
    client = @tasks.delete(json["id"])
    # send data to appropriate client ignoring responses with ids we don't know about
    if client
      client.send_data(data)
      client.close_connection_after_writing
    end
  rescue JSON::ParserError
    puts "invalid json in response receiving"
  end
  
  def schedule_request(connection, request)
    json = JSON.parse(request)
    @tasks[json["id"]] = connection
    send_data(request)
  rescue JSON::ParserError
    puts "invalid json in request scheduling"
  end
  
  def unbind
    EventMachine.stop
  end
end

module Forwarder
  
  attr_accessor :dispatcher
  
  def receive_data(data)
    dispatcher.schedule_request(self, data)
  end
  
  # def unbind
  #   # unschedule requests if connection has been dropped
  #   dispatcher.unschedule_requests(self)
  # end

end

EventMachine.run {
  Signal.trap("INT") { EventMachine.stop }
  Signal.trap("TERM") { EventMachine.stop }
  
  dispatcher = EventMachine.connect("127.0.0.1", 5587, TasksDispatcher)
  # EventMachine.start_server("127.0.0.1", 5588, Forwarder) do |fw|
  EventMachine.start_server("/tmp/forwarder.sock", nil, Forwarder) do |fw|
    fw.dispatcher = dispatcher
  end
}
