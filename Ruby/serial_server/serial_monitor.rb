require File.dirname(__FILE__) + "/serial_server"

class SimpleSerialClient
  def update(value)
    light = value.split(",").reject{|v| (v=='\n') || (v=='\r')}[0] unless value.nil?
    volume = value.split(",").reject{|v| (v=='\n') || (v=='\r')}[1] unless value.nil?
    puts "#{volume} #{light}"
    puts "amixer -c 1 sset Line,0 #{volume.to_f/1023 *100}%"
  end
end

#port   = ARGV[0] if ARGV[0]
#server = SerialServer.new(:port => port)

#server.add_observer SimpleSerialClient.new
#server.run