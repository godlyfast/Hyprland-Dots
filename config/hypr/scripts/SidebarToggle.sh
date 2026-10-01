#!/usr/bin/env bash
# Toggle the Booru sidebar via Quickshell IPC

if pgrep -f "qs.*booru-sidebar" > /dev/null; then
    qs -c booru-sidebar msg sidebarLeft toggle
else
    # Start sidebar shell, wait for its IPC to come up, then open it
    qs -c booru-sidebar >/dev/null 2>&1 &
    disown
    for _ in $(seq 1 25); do
        sleep 0.2
        if qs -c booru-sidebar msg sidebarLeft open >/dev/null 2>&1; then
            exit 0
        fi
    done
    exit 1
fi
