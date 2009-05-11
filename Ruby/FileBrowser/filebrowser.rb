# Creates an object that represents the current state of the a file browser window
# including sorting and filtering - perhaps this could at some point conform to the other ActiveRecord
# object methods in named_scopes, but for now, let's keep it simple

# ==== Usage ====
#
# filebrowser = FileBrowser.new('/Users/hksintl')
#
# files = filebrowser.filter('Downloads').sort('modified_at', 'asc').page(1)
#
# files = filebrowser.reset.files
  

class FileBrowser
	attr_accessor :root, :files, :total_entries, :per_page
	cattr_accessor :per_page
  
	# ----------
  # Initialization
	# ----------
	
	FileBrowser.per_page = 10
	
	def initialize(root, options = {})
		@files = []
		self.per_page = options[:per_page] || FileBrowser.per_page
		self.root     = root

    return self
	end
	
	class Error < RuntimeError; end
	class SortError < Error; end
	
	# ----------
	# getters, setters
  # ----------
  
	def root=(path)
		@root = path
    load_files
	end
	
	def per_page=(num)
		@per_page = num.to_i
	end
	
	# this methods seems implied, but it is not ... why?
	def per_page
		@per_page 
	end
	
  # ----------
	# filter
  # ----------
  
	# A very simple finder
	# Returns a FileBrowser
	
	def filter(query = nil)
    
    unless query.nil?
		  @files = @files.find_all{ |file| 
  		  file.name.match /#{query}/
  		} 
	  end
	  
		return self # Builder
	end
	
	#----------
	# sort
  #----------	

	# Returns a FileBrowser
	
	def sort(order, direction)
	  order     = order || :name
    order     = order.to_sym unless order.is_a? Symbol

	  direction = direction || :asc
	  direction = direction.to_sym unless direction.is_a? Symbol

		begin
			@files.sort!{ |a,b| 
				if direction == :asc
					a.send(order) <=> b.send(order)
				else
					b.send(order) <=> a.send(order)
				end
			}
		rescue NoMethodError => e
			# raising this sort of error should make more sense to rescue
			raise SortError
		end
		
		return self # Builder
	end
	
	#----------
	# page
  #----------
  
	# Returns a FileBrowser
		
	def page(page)
		page = page || 1
		page = page.to_i unless page.is_a? Integer
    
		# here we actually want the files
		return @files[(page - 1) * @per_page, @per_page]
	end

	#----------
	# load_files
  #----------
  
  # You should not need to call this method on an instance, but you could ...
  
	def load_files(show_hidden = false)
		files = Dir.new(@root).entries
		files.reject!{ |file| file =~ /^\./ } unless show_hidden

		@total_entries = files.size
		
		# Create file objects out of the names
		@files = files.map{ |file| 
			FileStat.new File.join(@root, file)
		}
		
		return @files # 
	end
	alias_method :reload, :load_files
	
end

# Creates a thin wrapper to allow for basic file info 
# to be easily accessible with reasonable names, 
# and mirrors the common column names on active record objects

class FileStat < File::Stat
	attr_reader :file
	
	def initialize(file)
		super
		@file = file
	end
	
	def created_at
		ctime
	end
	
	def modified_at
		mtime
	end
	alias_method :updated_at, :modified_at
	
	def path
		if directory?
			file
		else
			part = file.split('/'); part.pop; part.join('/')
		end
	end
	
	def basename
		@file.split('/').pop
	end
	alias_method :name, :basename
	
	def extension
		self.basename.split('.').pop if !directory?
	end
end
