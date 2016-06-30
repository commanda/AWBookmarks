TODO:
- [x] make a rightclick menu entry named "Add Bookmark"
- [x] figure out how to persist/save a bookmark entry
- [x] get the line text from the editor
- [x] get the line number from the editor
- [x] get the filename from the editor
- [x] make a bookmark tableviewcell
- [x] display a tableview of bookmark entries in our window
- [x] selecting a cell opens that file and scrolls to that line
- [x] and highlights it
- [x] and unfolds the method it's in, if folded
- [x] when you select, do the thing and then deselect the row
- [x] ctrl-b should bring the window to the forefront
- [x] detect when a document was edited
- [x] whenever a document is edited, update all bookmarks in that file cause they might have shifted around or their line deleted
- [x] if the document moves on disk, update our path to it (is this possible?)
- [x] delete a bookmark from the tableView
- [x] put cute little markers in the gutter 🦄
- [x] getting a registry of bookmarkEntries->line numbers to work with change/deletion of bookmarkEntries. -
- [x] BUG: display the hearts only in the correct files!
- [x] add a hotkey for bookmarking the current line (maybe use ctrl-b for that?)
- [x] choose a different marker symbol - red heart looks like compiler error
- [x] show the heart at the top of any folded section, just like breakpoints do
- [x] save/load bookmarkEntries to disk (use NSCoding)
- [x] ensure that adding a bookmark to the same spot where there already is one doesn't add a new one
- [x] when you open a bookmark, open its enclosing project, if there is one
- [x] dang editing feels laggy, maybe i need to put the "on file edited" thing on a bg thread?
- [x] rename "File Path" to "File" in the tableview
- [x] fix Untitled.crash
- [x] uh... fix the bug where tapping on the TinyTimerTests line 114 entry brings you to line 34? and there isn't a marker there? has something to do with opening xcode after quitting without saving the file maybe? but lines 114 and 34 are identical, so maybe it's just finding the wrong occurrence?
- [x] make sure the AWBookmarkEntry gets dealloced

- [x] really now, use the annotation drawing method instead of the line-drawing method. that way, the user can move and delete the breakpoint from the gutter, which it feels like they should be able to do
- [x] draw the markers in the correct files
- [x] have the markers draw at their full size, crossing over into the other gutter
- [x] keep the annotation objects around instead of creating new ones each time
- [ ] make the annotations trigger a redraw
- [ ] find a better way of getting what filename/url the current view is displaying
- [ ] fix delete-from-gutter.crash
- [ ] fix Xcode_blah.crash
- [ ] test with Xcode 8 Beta! if it works, add that uuid or whatever and release!

V 2.0
- [ ] instead of having the bookmarks on a separate panel, put them in the Navigator tab view in the main Xcode window
- [ ] have an outlineview i think, where you expand a project to see its bookmarks
- [ ] replace delete button with something nicer looking
- [ ] add a "comments" section to the bookmark entry and display it on the tableview
- [ ] attach bookmarks to a specific branch of a repo so you get them back when you checkout that repo

