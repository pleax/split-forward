require 'rubygems'
require 'eventmachine'
require 'json'

class Time
  def to_ms
    (to_f * 1000.0).to_i
  end
end

class TaskEnqueuer

  include EventMachine::Deferrable
  
  module Behaviour

    attr_accessor :delegate
    
    def receive_data(data)
      (@response_data ||= "") << data
    end

    def unbind
      if @response_data
        delegate.succeed(@response_data)
      else
        delegate.fail("Connection was hung up unexpectedly")
      end
    end
  end
  
  def initialize(server, port)
    @server, @port = server, port
  end
  
  def enqueue(data)
    client = EventMachine.connect(@server, @port, Behaviour)
    client.delegate = self
    client.send_data data
  end
  
end

EventMachine.run {
  Signal.trap("INT") { EventMachine.stop }
  Signal.trap("TERM") { EventMachine.stop }
  
  # task = TaskEnqueuer.new("127.0.0.1", 5588)
  task = TaskEnqueuer.new("/tmp/forwarder.sock", nil)
  task.callback { |result| puts result; EventMachine.stop }
  task.errback { |reason| puts reason; EventMachine.stop }
  task.enqueue({:id => Time.now.to_ms}.to_json)
}
