require 'spec'

describe FileBrowser do
  before :each do
    @path = File.join('.', 'browser')
    @file_browser = FileBrowser.new @path
  end
  
  it "should have the expected fields" do 
    @file_browser.per_page.should == 10
    @file_browser.root.should == @path
    @file_browser.files.should_not be_empty
    @file_browser.files.size.should == 13
    @file_browser.total_entries.should_not be_nil
  end
  
  it "should filter" do
    @file_browser.filter("text10").files.size.should == 1
    @file_browser.filter("text10").files.first.directory?.should be_false
  end
  
  it "should paginate" do
    @file_browser.page(1).size.should == 10
  end
  
  it "should sort" do 
    @file_browser = FileBrowser.new(@path)
    @file_browser.sort('name', 'asc').files.first.name.should == 'folder'
    @file_browser.sort('name', 'desc').files.first.name.should == 'text10.txt'
  end
  
  it "should raise a FileBrowserSortError if sorting on nonexistant field" do
    lambda {
      @file_browser.sort('duh', 'asc')
    }.should raise_error(FileBrowser::SortError)
  end
end