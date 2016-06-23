//
//  IDEHelpers.m
//  AWBookmarks
//
//  Created by Amanda Wixted on 5/20/16.
//  Copyright © 2016 Amanda Wixted. All rights reserved.
//

#import "IDEHelpers.h"

@class IDESourceCodeEditor;

@implementation IDEHelpers

+ (IDEWorkspaceTabController *)tabController
{
    NSWindowController *currentWindowController = [[NSApp keyWindow] windowController];
    if([currentWindowController isKindOfClass:NSClassFromString(@"IDEWorkspaceWindowController")])
    {
        IDEWorkspaceWindowController *workspaceController = (IDEWorkspaceWindowController *)currentWindowController;

        return workspaceController.activeWorkspaceTabController;
    }
    return nil;
}

+ (id)currentEditor
{
    NSWindowController *currentWindowController = [[NSApp mainWindow] windowController];
    if([currentWindowController isKindOfClass:NSClassFromString(@"IDEWorkspaceWindowController")])
    {
        IDEWorkspaceWindowController *workspaceController = (IDEWorkspaceWindowController *)currentWindowController;
        IDEEditorArea *editorArea = [workspaceController editorArea];
        IDEEditorContext *editorContext = [editorArea lastActiveEditorContext];
        id editor = [editorContext editor];
        return editor;
    }
    return nil;
}

+ (NSView *)gutterView
{
    NSView *__nullable gutterView = nil;
    IDESourceCodeEditor *editor = [self currentEditor];
    if([editor isKindOfClass:NSClassFromString(@"IDESourceCodeEditor")])
    {
        for(NSView *view in [editor.scrollView subviews])
        {
            if([NSStringFromClass([view class]) isEqualToString:@"DVTTextSidebarView"])
            {
                gutterView = view;
                break;
            }
        }
    }
    return gutterView;
}

+ (IDEWorkspaceDocument *)currentWorkspaceDocument
{
    NSWindowController *currentWindowController = [[NSApp mainWindow] windowController];
    id document = [currentWindowController document];
    if(currentWindowController && [document isKindOfClass:NSClassFromString(@"IDEWorkspaceDocument")])
    {
        return (IDEWorkspaceDocument *)document;
    }
    return nil;
}

+ (IDESourceCodeDocument *)currentSourceCodeDocument
{

    IDESourceCodeEditor *editor = [self currentEditor];

    if([editor isKindOfClass:NSClassFromString(@"IDESourceCodeEditor")])
    {
        return editor.sourceCodeDocument;
    }

    if([editor isKindOfClass:NSClassFromString(@"IDESourceCodeComparisonEditor")])
    {
        if([[(IDESourceCodeComparisonEditor *)editor primaryDocument] isKindOfClass:NSClassFromString(@"IDESourceCodeDocument")])
        {
            return (id)[(IDESourceCodeComparisonEditor *)editor primaryDocument];
        }
    }

    return nil;
}

+ (DVTSourceTextView *)currentSourceTextView
{
    DVTSourceTextView *textView;
    IDESourceCodeEditor *editor = [IDEHelpers currentEditor];
    if([editor isKindOfClass:NSClassFromString(@"IDESourceCodeEditor")])
    {
        textView = (DVTSourceTextView *)editor.textView;
    }
    else if([editor isKindOfClass:NSClassFromString(@"IDESourceCodeComparisonEditor")])
    {
        textView = (DVTSourceTextView *)((IDESourceCodeComparisonEditor *)editor).keyTextView;
    }
    return textView;
}

+ (NSString *)currentOpenProjectPath
{
    NSArray *workspaceWindowControllers = [NSClassFromString(@"IDEWorkspaceWindowController") valueForKey:@"workspaceWindowControllers"];

    id workSpace;

    for(id controller in workspaceWindowControllers)
    {
        if([[controller valueForKey:@"window"] isEqual:[NSApp keyWindow]])
        {
            workSpace = [controller valueForKey:@"_workspace"];
        }
    }

    NSString *workspacePath = [[workSpace valueForKey:@"representingFilePath"] valueForKey:@"_pathString"];
    return workspacePath;
}

@end
