require 'rubygems'
require 'eventmachine'

module ServiceTerminal
  
  include EventMachine::Protocols::LineText2
  
  @@connections = []
  
  def receive_line(input)
    @@connections.each do |client|
      client.send_data "#{input}\n"
    end
  end
  
  def self.attach_client(client)
    @@connections << client
  end
  
  def self.detach_client(client)
    @@connections.delete(client)
  end
end

module ServiceConnection
  
  def post_init
    ServiceTerminal.attach_client(self)
  end
  
  def receive_data(data)
    puts data
  end

  def unbind
    ServiceTerminal.detach_client(self)
  end
end

EventMachine.run {
  Signal.trap("INT") { EventMachine.stop }
  Signal.trap("TERM") { EventMachine.stop }

  EventMachine.start_server("127.0.0.1", 5587, ServiceConnection)
  EventMachine.open_keyboard(ServiceTerminal)
}
