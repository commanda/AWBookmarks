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

- [ ] really now, use the annotation drawing method instead of the line-drawing method. that way, the user can move and delete the breakpoint from the gutter, which it feels like they should be able to do
-draw the markers in the correct files
- [x] have the markers draw at their full size, crossing over into the other gutter
- [x] keep the annotation objects around instead of creating new ones each time
- [ ] make the annotations trigger a redraw
- [ ] find a better way of getting what filename/url the current view is displaying

- [ ] test with Xcode 8 Beta! if it works, add that uuid or whatever and release!

V 2.0
- [ ] instead of having the bookmarks on a separate panel, put them in the Navigator tab view in the main Xcode window
- [ ] have an outlineview i think, where you expand a project to see its bookmarks
- [ ] replace delete button with something nicer looking
- [ ] add a "comments" section to the entry and display it on the tableview

🦄
⛺

to find the DVTPluginCompatibilityUUID of the current Xcode to add to the Info.plist:


defaults read /Applications/Xcode.app/Contents/Info DVTPlugInCompatibilityUUID



(xcode 7.3.1 is  ACA8656B-FEA8-4B6D-8E4A-93F4C95C362C)

The location of the plugins is  ~/Library/Application\ Support/Developer/Shared/Xcode/Plug-ins

Note: If you accidentally clicked “Skip Bundle”, you can re-enable this alert by entering the following in Terminal:


defaults delete com.apple.dt.Xcode DVTPlugInManagerNonApplePlugIns-Xcode-6.3.2



Opening the right source code file
problem: we tell the NSApplicationDelegate to open the correct file, with the correct path, and it returns YES, but it still has whatever it has open open
how do we get it to actually open the file we want?
maybe use the Xcode navigator? what's that called?
IDEWorkspaceTabController seems promising

Notes:

see if we can listen to NSDocument to see if the file moves?

look at -[NSTextView scrollRangeToVisible:]  to put the bookmark on screen

in the bookmark entry:
store the line text
if the line text changes though,
search through the file fuzzy matching for that old line text
there will probalby be several lines that are exactly the same, so then weight them by distance from the original line number
have some threshold, so if we don't get a good enough match, delete that bookmark entry
use edit distance algorithm, use fuzzy matching algorithm

-[DVTTextSidebarView _drawLineNumbersInSidebarRect:foldedIndexes:count:linesToInvert:linesToReplace:getParaRectBlock:] 

-[IDEBreakpointIcon drawBreakpointAtPoint:inView: breakpointsActivated:breakpointEnabled:pressed:] 

(a fun session):
i put a breakpoint at -[NSView rightMouseDown:] 
now i'm stepping through that to find out what class has  _showMenuForEvent
looking at DVTSourceTextView because register rdi is that
rdi is the object that the method is being called on
i found that out by stepping through at that breakpoint til i got to a place right before that showMenuForEvent was called, then i used (lldb) re re to see the registers.
that showed me the 0x000 value of the pointer stored in register %rdi
then i did (lldb) po 0x000...
and it said DVTSourceTextView
hooray!

---------------------------------------------------

(lldb) po 0x000060800027ae00
<NSMenu: 0x60800027ae00>
Title:
Supermenu: 0x0 (None), autoenable: YES
Items:     (
        "<NSMenuItem: 0x600000aafa80 Cut>",
        "<NSMenuItem: 0x6000014ae880 Copy>",
        "<NSMenuItem: 0x6000014adfe0 Paste>",
        "<NSMenuItem: 0x6000014b0ce0 >",
        "<NSMenuItem: 0x6000014b1100 Find Selected Text in Workspace>",
        "<NSMenuItem: 0x6000014b08c0 Find Selected Symbol in Workspace>",
        "<NSMenuItem: 0x6000012b8b40 Find Call Hierarchy>",
        "<NSMenuItem: 0x6000014b0bc0 >",
        "<NSMenuItem: 0x6000014b1ac0 Show Issue>",
        "<NSMenuItem: 0x6000014b1a00 Jump to Definition>",
        "<NSMenuItem: 0x6000014b09e0 >",
        "<NSMenuItem: 0x6000014b0da0 Structure, submenu: 0x60000027ad40 (Structure)>",
        "<NSMenuItem: 0x6000014b0b00 >",
        "<NSMenuItem: 0x6000014b0f80 Discard Changes in Selected Files\U2026>",
        "<NSMenuItem: 0x6000014b1640 Show Blame for Line>",
        "<NSMenuItem: 0x6000014b0d40 >",
        "<NSMenuItem: 0x6000014b1760 Refactor, submenu: 0x600004a7a6c0 (Refactor)>",
        "<NSMenuItem: 0x6000014b0b60 >",
        "<NSMenuItem: 0x6000014b1a60 Open in\U2026>",
        "<NSMenuItem: 0x6000014b1940 Open in\U2026>",
        "<NSMenuItem: 0x6000014b19a0 Reveal in Project Navigator>",
        "<NSMenuItem: 0x6000014b0e00 Reveal in Symbol Navigator>",
        "<NSMenuItem: 0x6000014b0fe0 Show in Finder>",
        "<NSMenuItem: 0x6000014b1fa0 >",
        "<NSMenuItem: 0x6000014b0c80 Continue to Here>",
        "<NSMenuItem: 0x6000014b2420 >",
        "<NSMenuItem: 0x6000014b1b20 Test>",
        "<NSMenuItem: 0x6000014b1ca0 Profile>",
        "<NSMenuItem: 0x6000014b1b80 >",
        "<NSMenuItem: 0x6000014abdc0 Speech, submenu: 0x600004c72780 (Speech)>",
        "<NSMenuItem: 0x6000014b0800 >",
        "<NSMenuItem: 0x6000014b1dc0 Source Editor Help, submenu: 0x60000426c240 (recipe_source_editor)>"
    )

(lldb) bt
* thread #1: tid = 0x1a1998, 0x00007fff9b1d6c65 AppKit`-[NSView _showMenuForEvent:]  + 58, queue = 'com.apple.main-thread', stop reason = step out
  * frame #0: 0x00007fff9b1d6c65 AppKit`-[NSView _showMenuForEvent:]  + 58
    frame #1: 0x00007fff9ae29f7a AppKit`-[NSView rightMouseDown:]  + 100
    frame #2: 0x00007fff9ae29f08 AppKit`-[NSTextView rightMouseDown:]  + 181
    frame #3: 0x00000001008c694f DVTKit`-[DVTSourceTextView rightMouseDown:]  + 43
    frame #4: 0x00007fff9b1e9b15 AppKit`-[NSWindow _reallySendEvent:isDelayedEvent:]  + 2108
    frame #5: 0x00007fff9ac28539 AppKit`-[NSWindow sendEvent:]  + 517
    frame #6: 0x000000010169048a IDEKit`-[IDEWorkspaceWindow sendEvent:]  + 155
    frame #7: 0x00007fff9aba8ac7 AppKit`-[NSApplication sendEvent:]  + 2683
    frame #8: 0x00000001016d0ef2 IDEKit`-[IDEApplication sendEvent:]  + 894
    frame #9: 0x00007fff9aa0fdf2 AppKit`-[NSApplication run]  + 796
    frame #10: 0x00007fff9a9d9368 AppKit`NSApplicationMain + 1176
    frame #11: 0x000000010000139b Xcode`___lldb_unnamed_function1$$Xcode + 451
    frame #12: 0x00007fff8cddc5ad libdyld.dylib`start + 1
    frame #13: 0x00007fff8cddc5ad libdyld.dylib`start + 1
(lldb)

----------------------------------------------------

Resources:

the headers of Xcode:
https://github.com/luisobo/Xcode-RuntimeHeaders

specifically,
https://github.com/luisobo/Xcode-RuntimeHeaders/blob/master/DVTKit/DVTSourceTextView.h

a blog post on adding stuff to a context menu in an xcode plugin:
https://medium.com/@danwickes/adding-items-to-a-context-menu-in-an-xcode-plugin-a52679e30cc4#.hpgk5jnb7

the previous blog post:
https://medium.com/@danwickes/contributing-to-an-open-source-repository-d2158b6eddf9#.4lkgtqx5i

the open source thing they're talking about in those posts:
https://github.com/hanton/CopyIssue-Xcode-Plugin

the Aspect library:
https://github.com/steipete/Aspects

Rayrolling tutorial:
https://www.raywenderlich.com/94020/creating-an-xcode-plugin-part-1