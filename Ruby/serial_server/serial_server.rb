=begin

This is not a complete wrapper around the Ruby/SerialPort library,
only a very simple means of sending and receving data from the serial port

=end

Kernel::require "serialport"
require "observer"

class SerialServer
  include Observable
  attr_accessor :value, :serial_port
  
  def initialize(options = {})
    # params for serial port
    port = options[:port] #|| "/dev/ttyUSB0"  #may be different for you
    baud = options[:baud] || 9600
    data_bits = options[:data_bits] || 8
    stop_bits = options[:stop_bits] || 1
    parity    = SerialPort::NONE
    @value = ""
    
    unless port.nil?
      @serial_port = SerialPort.new(port, baud, data_bits, stop_bits, parity)
    else
      $stderr.print "Error! :: SerialServer#initialize - No USB port was specified.\n"
    end  

  end
  
  # 
  def self.list
     Dir.new("/dev").entries.select{|e| e =~ /tty\./}
  end
   
  # Intended to provide access out from serial port.
  # Named so that it could be used as an observer or send manually
  # The output is sent EXACTLY as it is recieved. Thus the sender must ensure format
  def update(value)
    @serial_port.puts value
  end
  
  # Main loop of execution
  def run
    loop do
      new_value = @serial_port.gets
      unless (@value == new_value) 
        @value = new_value
        changed
        notify_observers(@value)    
      end
    end
  end
end