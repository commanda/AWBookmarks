//
//  AWBookmarkEntry.m
//  AWBookmarks
//
//  Created by Amanda Wixted on 5/20/16.
//  Copyright © 2016 Amanda Wixted. All rights reserved.
//

#import "AWBookmarkEntry.h"
#import "AWBookmarksPlugin.h"
#import "CommonDefines.h"
#import "NSString+LevenshteinDistance.h"

#define THRESHOLD_SCORE 50

@interface AWMatch : NSObject
@property NSString *text;
@property CGFloat score;
@property NSInteger lineDistance;
@property int lineIndex;
@property CGFloat weightedScore;
@end

@implementation AWMatch

- (NSString *)description
{
    return [NSString stringWithFormat:@"\ntext: %@\nscore: %f\ndistance: %ld\nlineNumber: %d\nWEIGHTEDSCORE: %f\n", self.text, self.score, self.lineDistance, self.lineIndex, self.weightedScore];
}
@end


@interface AWBookmarkEntry ()

@end

@implementation AWBookmarkEntry

- (id)initWithCoder:(NSCoder *)decoder
{
    if(self = [super init])
    {
        @try
        {
            self.fileURL = [decoder decodeObjectForKey:@"fileURL"];
            self.lineNumber = [decoder decodeObjectForKey:@"lineNumber"];
            self.lineText = [decoder decodeObjectForKey:@"lineText"];
            self.uuid = [decoder decodeObjectForKey:@"uuid"];
            self.containingProjectURL = [decoder decodeObjectForKey:@"containingProjectURL"];
        }
        @catch(NSException *exception)
        {
            // Too legit to init
            self = nil;
        }
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.fileURL forKey:@"fileURL"];
    [encoder encodeObject:self.lineNumber forKey:@"lineNumber"];
    [encoder encodeObject:self.lineText forKey:@"lineText"];
    [encoder encodeObject:self.uuid forKey:@"uuid"];
    [encoder encodeObject:self.containingProjectURL forKey:@"containingProjectURL"];
}

- (id)copyWithZone:(NSZone *)zone
{
    AWBookmarkEntry *other = [[AWBookmarkEntry alloc] init];
    other->_fileURL = self->_fileURL;
    other->_lineNumber = self->_lineNumber;
    other->_lineText = self->_lineText;
    other->_uuid = self->_uuid;
    other->_containingProjectURL = self->_containingProjectURL;
    return other;
}

- (void)dealloc
{
    [[FileWatcher sharedInstance] stopWatchingFileAtURL:_fileURL];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@\n%@\nfilePath: %@\nlineNumber: %@\nlineText:%@\ncontainingProjectURL: %@", [super description], self.uuid, self.fileURL, self.lineNumber, self.lineText, self.containingProjectURL];
}

- (BOOL)isEqual:(id)object
{
    BOOL toReturn = NO;
    if([object isKindOfClass:[AWBookmarkEntry class]])
    {
        AWBookmarkEntry *other = (AWBookmarkEntry *)object;
        if([other.lineNumber isEqual:self.lineNumber]
           && [other.lineText isEqualToString:self.lineText]
           && [other.fileURL isEqual:self.fileURL])
        {
            toReturn = YES;
        }
    }
    return toReturn;
}

- (UUID *)uuid
{
    if(!_uuid)
    {
        _uuid = [[NSUUID UUID] UUIDString];
    }
    return _uuid;
}

- (void)setFileURL:(NSURL *)fileURL
{
    [[FileWatcher sharedInstance] stopWatchingFileAtURL:_fileURL];

    [self willChangeValueForKey:@"changed"];
    _fileURL = fileURL;
    [self didChangeValueForKey:@"changed"];

    __weak AWBookmarkEntry *weakSelf = self;
    [[FileWatcher sharedInstance] watchFileAtURL:fileURL
                                       onChanged:^(NSURL *currentURL) {
                                           DLOG(@"hey the file changed %@", currentURL);
                                           AWBookmarkEntry *strongSelf = weakSelf;
                                           if(strongSelf)
                                           {
                                               [strongSelf willChangeValueForKey:@"changed"];
                                               strongSelf->_fileURL = currentURL;
                                               [strongSelf didChangeValueForKey:@"changed"];
                                           }
                                       }];
}

- (void)highlightInTextView:(DVTSourceTextView *)textView
{
    NSString *text = [textView string];

    [self resolveInText:text
        runInBackgroundThread:NO
               afterResolving:^{
                   dispatch_async(dispatch_get_main_queue(), ^{
                       if(!_toBeDeleted)
                       {

                           // Have: line number and line text
                           // Need: the range of these characters in the whole string

                           __block NSRange rangeInText;

                           int targetLineNumber = [self.lineNumber intValue];
                           __block int lineNumber = 0;
                           [text enumerateSubstringsInRange:NSMakeRange(0, text.length - 1)
                                                    options:0
                                                 usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
                                                     lineNumber++;

                                                     if(lineNumber == targetLineNumber)
                                                     {
                                                         rangeInText = substringRange;
                                                         *stop = YES;
                                                     }
                                                 }];

                           if(rangeInText.location != NSNotFound)
                           {
                               [textView scrollRangeToVisible:rangeInText];
                               [textView setSelectedRange:rangeInText];
                           }
                       }
                   });
               }];
}

- (void)resolve
{
    NSString *text;

    // If our document is currently open, it might be different from the saved version on disk because the user is editing it and might not have saved
    NSURL *openURL = [[IDEHelpers currentSourceCodeDocument] fileURL];
    if([openURL isEqual:self.fileURL])
    {
        // Use the text from the open document instead of the text on disk
        text = [IDEHelpers currentSourceTextView].string;
    }
    else
    {
        text = [NSString stringWithContentsOfURL:self.fileURL encoding:NSUTF8StringEncoding error:nil];
    }

    [self resolveInText:text runInBackgroundThread:YES afterResolving:nil];
}

- (void)resolveInText:(NSString *)text runInBackgroundThread:(BOOL)runInBackgroundThread afterResolving:(void (^)(void))afterResolving
{
    void (^performResolve)(void) = ^void(void) {

        /*
         search through the file fuzzy matching for that old line text
         there will probably be several lines that are exactly the same, so then weight them by distance from the original line number
         have some threshold, so if we don't get a good enough match, delete that bookmark entry
         use edit distance algorithm, use fuzzy matching algorithm
         */

        if(text)
        {
            NSString *textCopy = [text mutableCopy];
            NSArray *lines = [textCopy componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];

            NSMutableArray *lineEvaluations = [[NSMutableArray alloc] init];

            int myLineIndex = _lineNumber.intValue - 1;

            for(int lineIndex = 0; lineIndex < lines.count; lineIndex++)
            {
                NSString *line = lines[lineIndex];
                NSInteger lineScore = [line levenshteinDistanceFromString:_lineText];
                NSInteger lineDistance = abs(myLineIndex - lineIndex);

                AWMatch *match = [[AWMatch alloc] init];
                match.text = line;
                match.score = lineScore;
                match.lineDistance = lineDistance;
                match.lineIndex = lineIndex;
                [lineEvaluations addObject:match];
            }

            [lineEvaluations sortUsingComparator:^NSComparisonResult(AWMatch *obj1, AWMatch *obj2) {
                if(obj1.score == obj2.score)
                {
                    return obj1.lineDistance > obj2.lineDistance;
                }
                else
                    return obj1.score > obj2.score;
            }];

            AWMatch *best = [lineEvaluations firstObject];

            if(best.lineIndex + 1 != self.lineNumber.intValue
               || ![self.lineText isEqualToString:best.text])
            {
                if(best.score < THRESHOLD_SCORE && best.text.length > 0)
                {
                    [self willChangeValueForKey:@"changed"];
                    self.lineNumber = @(best.lineIndex + 1);
                    self.lineText = best.text;
                    [self didChangeValueForKey:@"changed"];
                }
                else
                {
                    [self willChangeValueForKey:@"toBeDeleted"];
                    _toBeDeleted = YES;
                    [self didChangeValueForKey:@"toBeDeleted"];
                }
            }
        }

        if(afterResolving)
        {
            afterResolving();
        }

    };

    if(runInBackgroundThread)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), performResolve);
    }
    else
    {
        performResolve();
    }
}

- (void)setLineText:(NSString *)lineText
{
    _lineText = [lineText stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
}

#pragma FileWatcherDelegate method
- (void)fileDidChangeAtURL:(NSURL *)notification;
{
    [self resolve];
}

@end
