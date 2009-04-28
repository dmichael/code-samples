require 'json'

class QuicklistController < ApplicationController
  include ApplicationHelper
  before_filter :login_as_admin_required, :only => ['test']
  before_filter :load_quicklist_from_cookie
  layout 'main'
  
  # quicklist = {"v":["i":1,"c":0,"p":1], "p":false}  
  # v = array of videos
  # i = id
  # c = currently playing
  # p = parent playlist (if applicable)
  
  def play
    unless @quicklist.nil? or @quicklist["v"].empty?
      if last_played == last_in_queue
        @video = video_from_first_in_queue
        # play first
      else
        @video = next_video_in_queue(last_played)
      end 
      redirect_to video_detail_url(@video) << "?ql=true"
    else
      redirect_to home_uri
    end
  end
  
protected

  def last_played
    @quicklist["v"].find{ |video| video["c"] == true }
  end
  
  def last_in_queue
    @quicklist["v"].last()
  end
  
  def first_in_queue
    @quicklist["v"].first()
  end
  
  def video_from_first_in_queue
    logger.debug "video_from_first_in_queue"
    v = @quicklist["v"].first()
    reset_queue
    v["c"] = true
    resave_cookie
    return Video.find( v["i"] )
  end
  
  def reset_queue
    @quicklist["v"].each { |v| v["c"] = false }
  end
  
  def nothing_playing
    #this could happen if everything is deleted
    @quicklist["v"].all?{ |v| v["c"] == false }
  end
  
  def next_video_in_queue(last_played)
    logger.debug "next_video_in_queue"
    logger.debug @quicklist.inspect
    # wrap around
    if last_played == last_in_queue or nothing_playing
      video = video_from_first_in_queue
    else
      @quicklist["v"].each_with_index { |v, i|
        if last_played == v and v != last_in_queue
          reset_queue#@quicklist["v"][i]["c"] = false
          @quicklist["v"][i + 1]["c"] = true
          resave_cookie
          video = Video.find(@quicklist["v"][i + 1]["i"])
        end
      }
    end
    return video
  end
  
  def stop_playing
    @quicklist["v"].each { |video| video["c"] = false}
    resave
  end
  
  def resave_cookie
    cookies[:ql] = JSON::generate(@quicklist)
  end
  
  def load_quicklist_from_cookie
    @quicklist = (cookies[:ql])? JSON::parse(cookies[:ql]) : nil
  end

end