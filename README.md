# userFileReportandProfileDelete
the name kind of says it all.

So here's the thing, deleteing user profiles in windows, especially AD is kind of a pain. This is designed to help alleviate that. it handles local users and AD users pretty well. It also creates a report in C:\Users\public of every file that Get-ChildItem -Recurse -Force can find before deleting the user and their existing home directory.

It's fairly thoroughly commented.
