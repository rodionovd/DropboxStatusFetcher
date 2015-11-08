//
//  main.m
//  DropboxStatusFetcher
//
//  Created by Dmitry Rodionov on 11/5/15.
//  Copyright © 2015 Internals Exposed. All rights reserved.
//

@import Foundation;
#import "DropboxStatusFetcher.h"

int RDLog(NSString *format, ...)
{
    va_list vargs;
    va_start(vargs, format);
    NSString* message = [[NSString alloc] initWithFormat: format arguments: vargs];
    va_end(vargs);
    return printf("%s\n", message.UTF8String);
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        if (argc < 2) {
            RDLog(@"Usage: %s <file path>", argv[0]);
            return EXIT_SUCCESS;
        }

        NSString *target = @(argv[1]).stringByExpandingTildeInPath;
        DropboxStatusFetcher *fetcher = [DropboxStatusFetcher new];
        // Verify that Dropbox is actually running
        if ([fetcher isActive] == NO) {
            RDLog(@"%@", [DropboxStatusFetcher descriptionForSyncStatus: NotRunning]);
            return EXIT_SUCCESS;
        }

        DropboxSyncStatus status = [fetcher fileSyncStatusForFileAtURL: [NSURL fileURLWithPath: target]];
        // Dropbox will actually report "it's up to date" for non-existing files within the watched directory,
        // so we handle this case separately by verifing that the file exists in the first place
        if (status == UpToDate && [[NSFileManager defaultManager] fileExistsAtPath: target] == NO) {
            RDLog(@"%@", [DropboxStatusFetcher descriptionForSyncStatus: NotExist]);
            return EXIT_SUCCESS;
        }

        RDLog(@"%@", [DropboxStatusFetcher descriptionForSyncStatus: status]);
    }
    return 0;
}
