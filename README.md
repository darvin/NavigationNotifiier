# NavigationNotifiier
iOS application that shows navigation notifications from another iOS device


# Client app

Client app suppose to be run on the iOS device where Google Maps with turn by turn navigation and Music app that plays music are running. All it does is advertising the device as BLE peripheral, so Server app could discover it.
If no Server app is connected right now or previously, Client app shows "Expecting connection".
Once Server app was connected (even if this connection is not happens right now), Client app is in "paired mode". It remembers Server app between launches, and indicates "Paired with server (SERVER NAME)" and button "Unpair"
If server connected right now, app also indicates "Connected to Server (SERVER NAME)"
If server paired but not connected right now, app indicates "Expecting connection from (SERVER NAME)"

# Server app
App shows view separated in 2 parts:

## Connection
If no Client app is connected right now or paired, Server app shows button "Discover Client App".
 * When this button is pressed, it disappears and label "Discovering..." appears.
 * If nothing found, button appears again
If client discovered, Server app shows: "Connected to client: CLIENT NAME"
Once connected, "Disconnect" button appears.
Once connected, Server becomes paired to this Client, "Unpair" button appears, and "Discover Client App" button becomes "Connect to CLIENT NAME"

## Notifications


# Pairing routine
Client app exposes read only BLE characteristic "CLIENT NAME" which is equal to its own unique randomly generated persistive between launches name.
Client app exposes read write BLE characteristic "PAIRED SERVER NAME", set to "UNPAIRED" at initial launch. That is indication to Server app that Client app is ready to accept connection. Once connected, Server suppose to write to this characteristic its own name (randomly generated, device unique and persisting) and to remember CLIENT NAME for reconnection.
If server does not have previously remembered CLIENT NAME, it suppose to connect only to those Clients who have "PAIRED SERVER NAME" set to either "UNPAIRED" or to server name equal to Server's own server name. If it does have remembered CLIENT NAME, client name of client should be equal to it. If it is equal, but PAIRED SERVER NAME of client is different or UNPAIRED, server suppose to forget this client.
Server only performs discovery 30 seconds after "discover" button is pressed or once first Client is discovered. If during the connection Client's "PAIRED SERVER NAME" characteristic becomes "UNPAIRED", server suppose to drop connection.
Such complexity is nessecary to ensure one-to-one connection between Client and Server, and because Bluetooth device ids of iOS are unreliable - they are changing every reboot of device.
