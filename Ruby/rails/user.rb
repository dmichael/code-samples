=begin
  User model
=end
require 'digest/sha2'
class User < ActiveRecord::Base  
  attr_protected :hashed_password, :enabled
  attr_accessor :password
  
  validates_presence_of :login
  validates_uniqueness_of :login, :case_sensitive => :false  
  validates_length_of :login, :within => 3..64
  
  validates_login do |login|
    login.present
    login.unique    :case_sensitive => false
    login.formatted :with => /\A\w*\Z/, :message => "That account does not have a valid user name."
    login.length    :within => 4..15,
                    :too_long => "Too long",
                    :too_short => "Too short"
  end
  
  validates_email do |email|
    email.present            :message => "We need an email"
    email.unique             :case_sensitive => false,
                             :message => "This email is already in our database."
    email.formatted_as_email :message => "Oops! Your email address does not appear to be valid."
    email.length             :within => 3..100,
                             :too_short => "The email address you supplied is too short.",
                             :too_long => "The email address you supplied is too long."  
  end
  
  validates_password do |password|
    password.present   :if => :password_required?
    password.length    :within => 4..20, :if => :password_required?
    password.confirmed :if => :password_required?
  end
  validates_presence_of :password_confirmation, :if => :password_required?  


  
  has_and_belongs_to_many :roles 
  has_many :assets
  has_many :recordings
  has_many :soundfiles, :class_name => "Asset"#, :conditions => "type = 'Audio'"
  
  def before_save
    self.hashed_password = User.encrypt(password) if !self.password.blank?
  end
  
  def password_required?
    self.hashed_password.blank? || !self.password.blank?
  end
  
  def self.encrypt(string)
    return Digest::SHA256.hexdigest(string)
  end
  
  def self.authenticate(login, password)
    @loggedin = find_by_login_and_hashed_password_and_enabled(login, User.encrypt(password), true)
    #logger.debug @loggedin.nil?
  end
  
  def self.authenticate_machine(mac_address, passcode)
    # for the moment the only thing this does is to check that the machine knows how to get in... not whether or not it has an account
     User.encrypt( (mac_address << SECRET_WORD) ) == passcode
  end

  def has_role?(rolename) 
    self.roles.find_by_name(rolename) ? true : false 
  end 
  
  def is_administrator? 
    self.has_role?('Administrator')
  end
  
  
end
