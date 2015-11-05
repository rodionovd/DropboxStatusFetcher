# Dropbox Status Fetcher (for OS X)

Query a synchronization status of a local file in your [Dropbox](https://www.dropbox.com) folder. It would be one of `up_to_date`, `synchronizing`, `not_exist`, `sync_problem`, `not_running` or `ignored`.

Works on OS X (10.11. maybe earlier) with the latest version of Dropbox installed.


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

### Build & Run

Open the `.xcodeproj` file with Xcode and hit the *Run* button (<kbd>⌘</kbd>+<kbd>R</kbd>).

### Downloads

*to be done*

---

© Dmitry Rodionov, 2015
