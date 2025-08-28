#!/bin/bash
#    ___
#   / _ \___ _    _____ ____
#  / ___/ _ \ |/|/ / -_) __/
# /_/   \___/__,__/\__/_/
#

terminate_clients() {
  TIMEOUT=5
  # Get a list of all client PIDs in the current Hyprland session
  client_pids=$(hyprctl clients -j | jq -r '.[] | .pid')

  # Send SIGTERM (kill -15) to each client PID and wait for termination
  for pid in $client_pids; do
    echo ":: Sending SIGTERM to PID $pid"
    kill -15 "$pid"
  done

  start_time=$(date +%s)
  for pid in $client_pids; do
    # Wait for the process to terminate
    while kill -0 "$pid" 2>/dev/null; do
      current_time=$(date +%s)
      elapsed_time=$((current_time - start_time))

      if [ $elapsed_time -ge $TIMEOUT ]; then
        echo ":: Timeout reached."
        return 0
      fi

      echo ":: Waiting for PID $pid to terminate..."
      sleep 1
    done

    echo ":: PID $pid has terminated."
  done
}

safe_logout() {
  echo ":: Exit"

  terminate_clients
  sleep 0.5

  # Detect Wayland session only
  SESSION_ID=$(loginctl list-sessions --no-legend | grep "$USER" | awk '{print $1}' | while read id; do
    if loginctl show-session "$id" -p Type | grep -q "Type=wayland"; then
      echo "$id"
      break
    fi
  done)

  if [[ -n "$SESSION_ID" ]]; then
    echo ":: Terminating session $SESSION_ID"
    systemctl restart sddm
  else
    echo ":: Failed to find Wayland session, falling back to Hyprland --exit"
    Hyprland --exit
  fi

  sleep 2

}

# Handle args

case "$1" in
"exit")
  safe_logout
  ;;
"lock")
  echo ":: Lock"
  sleep 0.5
  hyprlock
  ;;
"reboot")
  echo ":: Reboot"
  terminate_clients
  sleep 0.5
  systemctl reboot
  ;;
"shutdown")
  echo ":: Shutdown"
  terminate_clients
  sleep 0.5
  systemctl poweroff
  ;;
"suspend")
  echo ":: Suspend"
  sleep 0.5
  systemctl suspend
  ;;
"hibernate")
  echo ":: Hibernate"
  sleep 1
  systemctl hibernate
  ;;
*)
  echo ":: Invalid argument. Use: exit | lock | reboot | shutdown | suspend | hibernate"
  ;;
esac
