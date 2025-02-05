#!/bin/bash

# Function to check if Borg is running
is_borg_running() {
    pgrep -x "borg" > /dev/null
}

print_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

echo "$(print_timestamp) - Waiting for Borg to finish..."

# Wait for Borg to finish
while is_borg_running; do
    sleep 30  # Check every 30 seconds
done

echo "$(print_timestamp) - Borg backup completed. Suspending now..."
systemctl suspend
