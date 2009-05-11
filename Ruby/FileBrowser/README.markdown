# FileBrowser

A simple class to help you with files and folders.

## Usage
    
    files = FileBrowser.new('/Users/hksintl').filter('Downloads').sort('modified_at', 'asc').page(1)

## Methods of interest

**#filter(string)**  
*Returns FileBrowser*  

**#sort(order, direction)**  
*Returns FileBrowser*  

**#page(number)**   
 *Returns an Array of FileStats*  

**#per_page=(number)**  


