# NavigationNotifiier
iOS application that shows navigation notifications from another iOS device


# Server app

Server app suppose to be run on the iOS device where Google Maps with turn by turn navigation and Music app that plays music are running. All it does is advertising the device as BLE peripheral, so Client app could discover it.
If no Client app is connected right now or previously, Server app shows "Expecting connection".
Once Client app was connected (even if this connection is not happens right now), Server app is in "paired mode". It remembers Client app between launches, and indicates "Paired with client (CLIENT NAME)" and button "Unpair"
If client connected right now, app also indicates "Connected to Client (CLIENT NAME)"
If client paired but not connected right now, app indicates "Expecting connection from (CLIENT NAME)"

# Client app
App shows view separated in 2 parts:

## Connection
If no Server app is connected right now or paired, Client app shows button "Discover Server App".
 * When this button is pressed, it disappears and label "Discovering..." appears.
 * If nothing found, button appears again
If server discovered, Client app shows: "Connected to server: SERVER NAME"
Once connected, "Disconnect" button appears.
Once connected, Client becomes paired to this Server, "Unpair" button appears, and "Discover Server App" button becomes "Connect to SERVER NAME"

## Notifications


# Pairing routine
Server app exposes read only BLE characteristic "SERVER NAME" which is equal to its own unique randomly generated persistive between launches name.
Server app exposes read write BLE characteristic "PAIRED CLIENT NAME", set to "UNPAIRED" at initial launch. That is indication to Client app that Server app is ready to accept connection. Once connected, Client suppose to write to this characteristic its own name (randomly generated, device unique and persisting) and to remember SERVER NAME for reconnection.
If client does not have previously remembered SERVER NAME, it suppose to connect only to those Servers who have "PAIRED CLIENT NAME" set to either "UNPAIRED" or to client name equal to Client's own client name. If it does have remembered SERVER NAME, server name of server should be equal to it. If it is equal, but PAIRED CLIENT NAME of server is different or UNPAIRED, client suppose to forget this server.
Client only performs discovery 30 seconds after "discover" button is pressed or once first Server is discovered. If during the connection Server's "PAIRED CLIENT NAME" characteristic becomes "UNPAIRED", client suppose to drop connection.
Such complexity is nessecary to ensure one-to-one connection between Server and Client, and because Bluetooth device ids of iOS are unreliable - they are changing every reboot of device.
