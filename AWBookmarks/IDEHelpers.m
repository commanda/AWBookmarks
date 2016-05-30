//
//  IDEHelpers.m
//  AWBookmarks
//
//  Created by Amanda Wixted on 5/20/16.
//  Copyright © 2016 Amanda Wixted. All rights reserved.
//

#import "IDEHelpers.h"

@implementation IDEHelpers

+ (IDEWorkspaceTabController*)tabController
{
    NSWindowController* currentWindowController =
    [[NSApp keyWindow] windowController];
    if ([currentWindowController
         isKindOfClass:NSClassFromString(@"IDEWorkspaceWindowController")]) {
        IDEWorkspaceWindowController* workspaceController = (IDEWorkspaceWindowController*)currentWindowController;
        
        return workspaceController.activeWorkspaceTabController;
    }
    return nil;
}

+ (id)currentEditor
{
    IDEWorkspaceWindowController* workspaceController = [self currentWorkspaceWindowController];
    IDEEditorArea* editorArea = [workspaceController editorArea];
    IDEEditorContext* editorContext = [editorArea lastActiveEditorContext];
    return [editorContext editor];
}

+ (IDEWorkspaceWindowController *)currentWorkspaceWindowController
{
    IDEWorkspaceWindowController *currentWindowController;
    NSArray *windows = [[NSApplication sharedApplication] windows];
    for(NSWindow *window in windows)
    {
        if([window.windowController isKindOfClass:NSClassFromString(@"IDEWorkspaceWindowController")])
        {
            currentWindowController = (IDEWorkspaceWindowController *)[window windowController];
            break;
        }
    }
    return currentWindowController;
}

+ (IDEWorkspaceDocument*)currentWorkspaceDocument
{
    NSWindowController* currentWindowController =
    [[NSApp mainWindow] windowController];
    id document = [currentWindowController document];
    if (currentWindowController &&
        [document isKindOfClass:NSClassFromString(@"IDEWorkspaceDocument")]) {
        return (IDEWorkspaceDocument*)document;
    }
    return nil;
}

+ (IDESourceCodeDocument*)currentSourceCodeDocument
{
    
    IDESourceCodeEditor* editor = [self currentEditor];
    
    if ([editor isKindOfClass:NSClassFromString(@"IDESourceCodeEditor")]) {
        return editor.sourceCodeDocument;
    }
    
    if ([editor
         isKindOfClass:NSClassFromString(@"IDESourceCodeComparisonEditor")]) {
        if ([[(IDESourceCodeComparisonEditor*)editor primaryDocument]
             isKindOfClass:NSClassFromString(@"IDESourceCodeDocument")]) {
            return (id)[(IDESourceCodeComparisonEditor*)editor primaryDocument];
        }
    }
    
    return nil;
}

@end
