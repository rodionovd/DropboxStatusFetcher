//
//  main.m
//  DropboxStatusFetcher
//
//  Created by Dmitry Rodionov on 11/5/15.
//  Copyright © 2015 Internals Exposed. All rights reserved.
//

@import Foundation;
#import "DropboxStatusFetcher.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {

        if (argc < 2) {
            printf("Usage: %s <file path>\n", argv[0]);
            return EXIT_SUCCESS;
        }
        NSString *target = @(argv[1]).stringByExpandingTildeInPath;
        DropboxStatusFetcher *fetcher = [DropboxStatusFetcher new];
        // Verify that Dropbox is actually running
        if ([fetcher isActive] == NO) {
            printf("%s\n", [DropboxStatusFetcher descriptionForSyncStatus: NotRunning].UTF8String);
            return EXIT_SUCCESS;
        }
        DropboxSyncStatus status = [fetcher fileSyncStatusForFileAtURL: [NSURL fileURLWithPath: target]];
        // Dropbox will report "it's up to date" even for non-existing files within the watched directory,
        // so we handle this case separately by verifing that the file actually exists
        if (status == UpToDate && [[NSFileManager defaultManager] fileExistsAtPath: target] == NO) {
            printf("%s\n", [DropboxStatusFetcher descriptionForSyncStatus: NotExist].UTF8String);
            return EXIT_SUCCESS;
        }

        printf("%s\n", [DropboxStatusFetcher descriptionForSyncStatus: status].UTF8String);
    }
    return 0;
}
