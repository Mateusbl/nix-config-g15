# Questions for the owner

Decisions the config cannot make on its own. Each one lists the default that is in place now.

## Lock screen: ctOS too?

The login screen is now ctOS. Its lock mode (`CTOS_MODE=lockd`) could replace hyprlock, so locking
and logging in look the same. hyprlock stays for now: if the ctOS locker ever froze, the session
could only be recovered from another console (`Ctrl+Alt+F2`, then
`hyprctl --instance 0 dispatch 'hl.dsp.exit()'`), which loses unsaved work, while hyprlock is the
Hypr tool made for this. *Default: hyprlock.*
