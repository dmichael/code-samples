=begin
  Anuran base class for simulation of various anuran species
  
  Author::    David M Michael
  Copyright:: Copyright (c) (p) 2008 Unnature, LLC
  License::   You may not use or distribute this class without written permission.
  Contact::   david@unnature.net
  
  Description::
  This is a Ruby-based composite Ugen using C++ externals to compose a new unit
  There are few crucial internal variables that should be set. 

  1) :cpg is the central pattern generator that generates signals to trigger the voice.
  2) :voicebox is the Ugen that will be the actuator.
  3) :coords is an array of [x,y] location coordinates - in the future, this may need to be stored elsewhere
  4) :spl is the sound pressure level of the actuator/voicebox at the source
=end
require 'marionette'
require 'greenfield'

def rand_range(a, b)
  rand*(b-a)+a
end

class Anuran
  cattr_accessor :audio_root
  attr_accessor :cpg, :actuator, :alt_sample, :samples, :position, :spl, :call_duration, :message, :host_data, :bout_frequency, :threshold, :is_playing
  
  def initialize(options = {})
    # Create the actuator
    @samples = []
    @actuator = SoundFile.new
    #@panner = Panner.new @actuator, options[:position]
    if options[:file] 
      @actuator.open options[:file]
      @actuator.rate = options[:rate] || rand_range(0.95, 1.05)
      @call_duration = @actuator.duration
      @samples.push @actuator 
    end
    if options[:alt_file]
      @alt_sample = SoundFile.new
      @alt_sample.open options[:alt_file]
      @alt_sample.rate = options[:rate] || rand_range(0.95, 1.05)
      #@call_duration = @actuator.duration
      @samples.push @alt_sample
    end
    @position = options[:position]
    x, y = options[:position]
    # Make the CPG
    # if the options are nil, then the default contructor values are used
    @cpg = Greenfield.new(
            :period => options[:period],
            :effector_delay => options[:effector_delay],
            :decending_length => options[:decending_length],
            :prc_slope => options[:prc_slope],
            :x => x,
            :y => y,
            :rebound => options[:rebound],
            :threshold => options[:threshold],
            :spl => options[:spl],
            :call_duration => @call_duration,
            :acceleration => options[:acceleration] || 0.0
           )
    # The actuator here is really just an observer of the CPG
    # NB: other CPGs can be observers of this CPG, effectively coupling them
    #@cpg.add_observer @actuator
    @cpg.actuator = @actuator
    @cpg.pan = rand_range(-1.0, 1.0)
    @bout_frequency = options[:bout_frequency]
    @threshold = options[:threshold] # this should be the CPG!!
    
  end
    
  def move(coords)
    @x, @y = coords unless coords.size != 2
  end

  # Defines the play method just as other C++ based Ugens do
  def play
    Audio::Out.add @cpg
    @is_playing = true
    #Audio::Out.add @actuator
  end

  # Defines the stop method just as other C++ based Ugens do  
  def stop
    Audio::Out.remove @cpg
    @is_playing = false
    #Audio::Out.remove @actuator
  end

  # indirect observer access  
  def listen_to(o)
    o.add_observer(self.cpg)
  end

  # indirect observer access  
  def stop_listening_to(o)
    o.remove_observer(self.cpg)
  end
  
  # direct classic observer access
  def add_observer(o)
    @cpg.add_observer(o)
  end
  
  # direct classic observer access  
  def remove_observer(o)
    @cpg.remove_observer(o)
  end

  # this is for observing the CircadianRhythm (observable)
  def update(sender, value)    
    if sender.is_a? RegulationCycle
      @cpg.call_potential = value
      
      # The following has the potential to alter the dynamics of the chorus, but may be necessary to save computational power.
      # Since a frog is not being actively evaluated, it is not being stimulated by its neighbors.
      # the only hope is to "schedule" it far enough in advance to allow for the potential for stimulation
      # and visa versa, to remove it from the Bus well after it has stopped playing
      
      # remove from the bus if not scheduled to play!!!
      if ((value + 0.2) < @threshold ) and @is_playing and @actuator.is_finished?
        puts "Removing an Anuran from the Bus"
        stop
      end
      # add to the bus if scheduled to play!!!
      if ((value - 0.2) > @threshold ) and !@is_playing
        puts "Putting an Anuran back on the Bus"
        play
      end
    end
  end
  
end