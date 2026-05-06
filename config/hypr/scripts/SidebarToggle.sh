#!/usr/bin/env bash
# Toggle the Booru sidebar via Quickshell IPC

# Check if sidebar shell is running
if pgrep -f "qs.*booru-sidebar" > /dev/null; then
    # Send toggle command via IPC
    qs -c booru-sidebar msg sidebarLeft toggle
else
    # Start sidebar shell and open it
    qs -c booru-sidebar &
    sleep 0.3
    qs -c booru-sidebar msg sidebarLeft open
fi
