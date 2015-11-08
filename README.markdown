# Dropbox Status Fetcher (for OS X)

Query a synchronization status of a local file in your [Dropbox](https://www.dropbox.com) folder. It should be either:

1. File is up to date.
2. File is synchronizing now.
3. File doesn't exist.
4. There is a sync error.
5. File is ignored (i.e. excluded from sync).
6. Dropbox application is not running.

### Requirements

You should have [Dropbox.app](https://www.dropbox.com/install) up and running.

### Compatibility

Tested on OS X 10.11 with Dropbox.app (3.10.9) installed. Might work with older versions as well

### Usage

```shell
$ ./DropboxStatusFetcher <file path>
```

Examples:

```shell
$ ./DropboxStatusFetcher ~/Dropbox/
# > up_to_date

$ ./DropboxStatusFetcher ~/Dropbox/FileThatDontSyncLocally
# > ignored

$ ./DropboxStatusFetcher ~/Dropbox/MyMovie.m4v
# > synchronizing
```

### How to build

Open the `.xcodeproj` file with Xcode and hit the *Build* button (<kbd>⌘</kbd>+<kbd>B</kbd>).

---

© Dmitry Rodionov, 2015
