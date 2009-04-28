=begin

  This is an example of a Rails integration test, based on Test::Unit
  This file is included in a suite of tests standard in a (Ruby on) Rails application
  
=end

require "#{File.dirname(__FILE__)}/../test_helper"

class AdminShowListPanelIntegrationTest < ActionController::IntegrationTest
  def setup
    # prime the session variable
    get "/"
    Network.destroy_all
    ShowListPanel.destroy_all
    @user = custom_user :admin => true
    login_as @user, 'test'
    @shows = ( 1..3 ).map { |i| default_show }
    # create one valid video for each show
    @shows.each { |s| custom_video( :show_id => s.id ) } 
    @network_page = default_network_page
    @shows.each{|n| n.update_attribute( :has_clip_logo, true )}

    @page_table_name = @network_page.class.name.tableize
    @page_type = @network_page.class.name
    @page_id = @network_page.id
  end

  def test_list
    get "/admin/#{@page_table_name}/#{ @page_id }/show_list_panels/"
    assert_response :success
    # test the generated route
    get admin_show_list_panels_path(@page_table_name, @page_id)
    assert_response :success
  end
  
  def test_new
    get "/admin/#{@page_table_name}/#{ @page_id }/show_list_panels/new"
    assert_response :success
    get new_admin_show_list_panel_path(@page_table_name, @page_id)
    assert_response :success
  end
  
  def test_create
    new_show_list_panel_show_attributes = {}
    @shows.each_with_index do |show, i|
      new_show_list_panel_show_attributes[i.to_s] = { :show_id => show.id }
    end
    
    post "/admin/#{@page_table_name}/#{ @page_id }/show_list_panels", {
      :commit => 'Create', :live_at_blank => '1', :not_live_at_blank => '1',
      :show_list_panel => {
        :title => 'whatever',
        :page_type => @page_type,
        :page_id => @page_id,
        :new_show_list_panel_show_attributes =>
          new_show_list_panel_show_attributes
        }
    }
      
    assert_response :redirect, @response.body
    @show_list_panel = ShowListPanel.find :first
    
    assert_equal 'whatever', @show_list_panel.title
    assert_equal @page_type, @show_list_panel.page_type
    assert_equal @page_id, @show_list_panel.page_id
    
  end
  
  #TODO: This needs to be elaborated upon
  def test_preview_for_new
    show_list_panel = ShowListPanel.create(:title => 'my first mm', :page => @network_page)

    get preview_new_admin_show_list_panel_path(@page_table_name, @page_id,  
      :show_list_panel => {
        :title => "this is really cool", 
        "live_at(4i)"=>"14", "live_at(1i)"=>"2008", "live_at(2i)"=>"4", "live_at(3i)"=>"30",
        :new_show_list_panel_show_attributes => {
          "1" => {"show_id"=>"#{@shows[0].id}", "position"=>"2"}, 
          "2" => {"show_id"=>"#{@shows[1].id}", "position"=>"3"}, 
          "3" => {"show_id"=>"#{@shows[2].id}", "position"=>"1"}
        }
          
        })
    assert :success, @response.body
    #TODO: verify that this actually works!
  end
end
