//
//  DropboxStatusFetcher.h
//  DropboxStatusFetcher
//
//  Created by Dmitry Rodionov on 11/6/15.
//  Copyright © 2015 Internals Exposed. All rights reserved.
//

@import Foundation;

typedef NS_ENUM(NSInteger, DropboxSyncStatus) {
    NotExist = 0,
    UpToDate = 1,
    SynchronizingNow = 2,
    SynchronizationError = 3,
    Ignored = 4,
    NotRunning = 5
};

@interface DropboxStatusFetcher : NSObject

- (instancetype)init NS_DESIGNATED_INITIALIZER;

// Map DropboxSyncStatus into NSString*
+ (NSString *)descriptionForSyncStatus: (DropboxSyncStatus)status;
// Request a sync status for the file
- (DropboxSyncStatus)fileSyncStatusForFileAtURL: (NSURL *)fileURL;
// Is Dropbox active running right now?
- (BOOL)isActive;
@end
