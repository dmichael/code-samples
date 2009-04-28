/*
  class Quicklist
  
  The Quicklist is stored in a cookie of the following format.
  quicklist = {"v":["i":1,"c":0,"p":1], "p":false}  
  v = array of videos
  i = id
  c = currently playing
  p = parent playlist (if applicable)
  
  This class is initialized on inclusion (see bottom) and used in conjuction with quicklist_controller.rb
  There are some dependent classes, such as Cookie and FlashVideo, not included
  This file uses the Prototype JS framework.
*/
var Quicklist = 
{ 
  // Array of videos (just a data store...)
  // This gets converted to a cookie on save()
  videos: [], 
  playing: false,
  // initialize
  initialize: function() {
    if(!Cookie.get("ql")) {
      Cookie.set("ql", Object.toJSON({ "v":[], "p":false }), "2");  
    }
    else {
      Quicklist.videos = Cookie.get("ql").evalJSON().v;
      Quicklist.playing = Cookie.get("ql").evalJSON().p;
    } 
    return Cookie.get("ql");
  },
  
  play: function(uri){
    //not used yet
  },
  
  cue_next: function(){
    FlashVideo.auto_load = null;
  },
  
  clear: function(){
    Quicklist.videos.each(function(video){
      console.log(video.i)
      console.log($$('[name="toggle-video-'+video.i+'"]').size())
       if($$('[name="toggle-video-'+video.i+'"]').size() > 0){
         $$('[name="toggle-video-'+video.i+'"]').each(function(element){
            element.className = 'add';
          })
        }
    });
    
    Quicklist.videos.clear();
    Cookie.erase("ql");
    $$('[name="quicklist-menu-item"]').each(function(element){ element.fade(); });
    $('quicklist-size').innerHTML = Quicklist.videos.size();
  },
  
  toggle_video: function(event, id){
    var element  = Event.element(event);
    var video_id = (video_id)? id : Event.element(event).id.split('-').last();
    var video_exists = false;
    
    try{console.log(Cookie.get("ql"));}catch(e){}
   
    this.videos.each(function(video){
      if(video.i == video_id){
        video_exists = true; // the video is already in the quicklist
        return;
      } 
    });

    if(video_exists){
      Quicklist.remove_video(video_id);
      if(!id) $$('[name="toggle-video-'+video_id+'"]').each( function(element){ element.className = 'add'; } );
    } 
    else{
      Quicklist.add_video(video_id);
      if(!id) $$('[name="toggle-video-'+video_id+'"]').each(function(element){ element.className = 'added'; }); 
    }
  },
  
  // add video
  add_video: function(video_id, playlist_id) 
  {
    // account for a playlist ID
    if(playlist_id) item["p"] = playlist_id;
    // do not add the video twice to the quicklist
    var video_exists = false;
    Quicklist.videos.each(function(video){
      if(video.i == video_id) video_exists = true;
    });
    // push the new clip onto the stack
    if(!video_exists){
      var item = {"i":video_id, "c":false};
      Quicklist.videos.push(item);
      Quicklist.save();
    } 
  },
  
  // remove video
  remove_video: function(video_id)
  {  
    var position = 0;
    Quicklist.videos.each(function(video){
      if(video.i == video_id){
        // Remove the clip from the array
        Quicklist.videos.splice(position, 1);
        try{
          if($$('[name="toggle-video-'+video_id+'"]').size() > 0){
           $$('[name="toggle-video-'+video_id+'"]').each(function(element){
              element.className = 'add';
            })
          } 
        }
        catch(e){
        }
        // Save the cookie
        Quicklist.save();
        return;
      }
      else{
        position++;
      }
    });
  },
  
  // save
  save: function() 
  {
    var cookie = Cookie.get("ql")
    if(!cookie) cookie = Quicklist.initialize(); // the cookie has been deleted, lets make a new one.
    
    var quicklist = cookie.evalJSON();
    quicklist.v = Quicklist.videos;
    quicklist.p = Quicklist.playing;
    Cookie.set("ql", Object.toJSON(quicklist), "2");  
    Quicklist.update_menu();
    try{console.log(Cookie.get("ql"));}catch(e){}
  },
  
  // erase
  erase: function(element){
    Cookie.erase("ql");
    $(element).innerHTML = "";
  },
    
  render: function(element) {
    try {
      if(Cookie.get("ql").evalJSON().v.size() > 0) {
        new Ajax.Updater(element, '/playlist/quicklist/' + this.key(), {method:"get"} );  
      }
    }catch(e){}
  },
  
  toggle_menu: function(){
	  var quicklist_menu = $("quicklist-menu");
		var position = Position.cumulativeOffset( $("quicklist-menu-link") );
	  var left 		 = position[0];
   	// get new layer and show it
		quicklist_menu.style.left = left + 'px';
		if(quicklist_menu.visible()){
		  quicklist_menu.hide();
		}
		else{
      Quicklist.update_menu(true);
		}
  },
  
  update_menu: function(show_on_update){
    var quicklist_menu = $("quicklist-menu");
    if(quicklist_menu.visible() || show_on_update){
      new Ajax.Updater('quicklist-menu', '/playlist/show', {
        method: 'get',
        onComplete: function(transport){
          if(show_on_update) $("quicklist-menu").show();          
        }
      });
    }
      
  },
  
  // Key used to caching - this is a unique identifier only
  key: function()
  {
    var quicklist = Cookie.get("ql").evalJSON();
    var ids = [];
    var temp = "";
    quicklist.v.each(function(video){ 
      temp = video["i"];
      if(video["p"]) temp += video["p"];
      ids.push(temp);
    });
    var hash = hex_md5(ids.join(","));
    return hash;
  }
}
// make sure that the data is current when this is loaded
Quicklist.initialize();

