#!/bin/bash
#
# Notify of Homebrew updates via Notification Center on Mac OS X
#
# Author: Chris Streeter http://www.chrisstreeter.com
# Requires: terminal-notifier. Install with:
#   brew install terminal-notifier

TERM_APP='/Applications/iTerm.app'
BREW_EXEC='/usr/local/bin/brew'
GROWL_NOTIFY=`which growlnotify`
GROWL_TITLE="Homebrew Update(s) Available"
GROWL_ARGS="-n Homebrew -a $TERM_APP -d $GROWL_NOTIFY -a $BREW_EXEC"
NOTIF_ARGS="-execute '/usr/local/bin/brew upgrade --all'"
BREW_ICON="/Users/morgan/Documents/brew.png"

$BREW_EXEC update 2>&1 > /dev/null
outdated=`$BREW_EXEC outdated --quiet`
pinned=`$BREW_EXEC list --pinned`

# Remove pinned formulae from the list of outdated formulae
outdated=`comm -1 -3 <(echo "$pinned") <(echo "$outdated")`

if [ -z "$outdated" ] ; then
    if [ -e $GROWL_NOTIFY ]; then
        # No updates available
        $GROWL_NOTIFY $GROWL_ARGS -m '' -t "No Homebrew Updates Available"
    fi
else
    # We've got an outdated formula or two

    # Nofity via Notification Center
    if [ -e $GROWL_NOTIFY ]; then
        lc=$((`echo "$outdated" | wc -l`))
        outdated=`echo "$outdated" | tail -$lc`
        message=`echo "$outdated" | head -5`
        if [ "$outdated" != "$message" ]; then
            message="Some of the outdated formulae are:
$message"
        else
            message="The following formulae are outdated:
$message"
        fi
        # Send to the Nofication Center
        echo "$message" | $GROWL_NOTIFY $GROWL_ARGS -s -t $GROWL_TITLE
    fi
fi
