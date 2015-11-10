//
//  DropboxStatusFetcher.m
//  DropboxStatusFetcher
//
//  Created by Dmitry Rodionov on 11/6/15.
//  Copyright © 2015 Internals Exposed. All rights reserved.
//

#import "DropboxStatusFetcher.h"

static NSString * const kDropboxStatusFetcherRunLoopMode = @"DropboxStatusFetcherRunLoopMode";

#define HUMAN_READABLE_DESCRIPTIONS 1
#define kTimeout (3)

@interface DropboxStatusFetcher() <NSMachPortDelegate>
{
    uint64_t _lastMsgIndex;
}
@property (strong) NSMachPort *localPort, *remotePort;
@property (strong) NSData *lastResponse;

// Request a list of curently watched directories (e.g. ~/Dropbox)
- (NSSet *)_watchSet;
@end

@implementation DropboxStatusFetcher

- (instancetype)init
{
    if ((self = [super init])) {
        // Setup a local port for listening
        _localPort = [[NSMachPort alloc] init];
        [[NSRunLoop mainRunLoop] addPort: _localPort forMode: NSDefaultRunLoopMode];
        [[NSRunLoop mainRunLoop] addPort: _localPort forMode: kDropboxStatusFetcherRunLoopMode];
        [_localPort setDelegate: self];
        [self connect];
    }
    return self;
}

- (void)dealloc
{
    [self.localPort setDelegate: nil];
}

#pragma mark - Public API

- (DropboxSyncStatus)fileSyncStatusForFileAtURL: (NSURL *)fileURL
{
    NSMutableData *data = [[NSMutableData alloc] init];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData: data];
    [archiver encodeObject: fileURL forKey: @"url"];
    [archiver finishEncoding];

    id archivedData = [self sendRequestOfType: 0x65 withData: data];
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData: archivedData];
    NSAssert([unarchiver containsValueForKey: @"status"], @"");
    int32_t status = [unarchiver decodeInt32ForKey: @"status"];
    return status;
}

- (BOOL)isActive
{
    return self.remotePort.isValid && [self _watchSet].count > 0;
}

#pragma mark - Implementation Details

- (NSSet *)_watchSet
{
    // Send an empty payload in order to request the current watch set
    NSMutableData *data = [[NSMutableData alloc] init];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData: data];
    [archiver finishEncoding];

    id archivedData = [self sendRequestOfType: 0x64 withData: data];
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData: archivedData];
    NSAssert([unarchiver containsValueForKey: @"watch_set"], @"");
    return [unarchiver decodeObjectForKey: @"watch_set"];
}

+ (NSString *)descriptionForSyncStatus: (DropboxSyncStatus)status
{
#if HUMAN_READABLE_DESCRIPTIONS
    switch (status) {
        case NotExist: return @"No such file or directory";
        case UpToDate: return @"The file is up to date";
        case SynchronizingNow: return @"The file is synchronizing";
        case SynchronizationError: return @"There's a synchronization problem. Try again later";
        case Ignored: return @"The file is ignored (i.e. excluded from sync)";
        case NotRunning: return @"Dropbox application is not running";
    }
#else
    switch (status) {
        case NotExist: return @"not_exist";
        case UpToDate: return @"up_to_date";
        case SynchronizingNow: return @"synchronizing";
        case SynchronizationError: return @"sync_problem";
        case Ignored: return @"ignored";
        case NotRunning: return @"not_running";
    }
#endif
    return @"<???>";
}

- (void)connect
{
    // Obtain a remote port for the Dropbox's Garcon service
    NSString *portName = [NSString stringWithFormat: @"com.getdropbox.dropbox.garcon.cafe_%u", getuid()];
    NSMachBootstrapServer *server = [NSMachBootstrapServer sharedInstance];
    _remotePort = (NSMachPort *)[server portForName: portName];
    if (_remotePort != nil) {
        // Say hello
        NSMutableData *data = [[NSMutableData alloc] init];
        NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData: data];
        [archiver encodeObject: @"1.11" forKey: @"version"];
        [archiver finishEncoding];
        if ([self sendRequestOfType: 0 withData: data] == nil) {
            self.remotePort = nil;
            NSLog(@"Failed to connect to Dropbox!");
        }
    }
}

- (id)sendRequestOfType: (int)type withData: (NSData *)data
{
    if (self.remotePort == nil || self.remotePort.isValid == NO) {
        NSLog(@"Reconnecting.");
        [self connect];
    }
    NSAssert(self.remotePort != nil, @"Invalid remote port, not sending a message.");

    _lastMsgIndex++;
    NSData *numberData = [NSData dataWithBytes: &_lastMsgIndex length: sizeof(_lastMsgIndex)];
    NSPortMessage *message = [[NSPortMessage alloc] initWithSendPort: self.remotePort
                                                         receivePort: self.localPort
                                                          components: @[numberData, data]];
    message.msgid = type;
    self.lastResponse = nil;

    if (NO == [message sendBeforeDate: [[NSDate alloc] initWithTimeIntervalSinceNow: kTimeout]]) {
        NSLog(@"Timed out sending the request!");
        return nil;
    }

    [self waitForResponse];
    return self.lastResponse;
}

- (void)waitForResponse
{
    [[NSRunLoop mainRunLoop] runMode: kDropboxStatusFetcherRunLoopMode
                          beforeDate: [[NSDate alloc] initWithTimeIntervalSinceNow: kTimeout]];
}

- (void)handlePortMessage: (NSPortMessage *)message
{
    if (message.components.count < 2) {
        NSLog(@"Invalid reponse: payload is missing");
        self.lastResponse = nil;
    } else {
        self.lastResponse = [message.components lastObject];
    }
}

@end
