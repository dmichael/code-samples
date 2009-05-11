# FileBrowser

A simple class to help you with files and folders.

## Usage

    filebrowser = FileBrowser.new('/Users/hksintl')
    
    files = filebrowser.filter('Downloads').sort('modified_at', 'asc').page(1)

    files = filebrowser.reset.files

## Methods of interest

**filter(string)**  return
*Returns FileBrowser*  

**sort(order, direction)**  return 
*Returns FileBrowser*  

**page(number)**  return 
*Returns an Array of FileStats*  


