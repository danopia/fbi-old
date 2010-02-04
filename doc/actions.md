FBI Packet Actions
==================

The action of each packet is stored in the "action" entry on the root hash.

### auth
Auth is the first packet that is sent to the FBI server after a component makes
a connection. It has a simple structure, consisting of a "user" and "secret".
Both are strings. The "secret" entry is removed after being processed by the
server and then the rest of the packet is sent back to the client as an ACK.

### subscribe
The subscribe action is used by outputs to sign up for data broadcasts. The
single entry in this packet is "channels", whose value is an array of strings
to subscribe to. The entire packet is echoed back after processing.

### private
Private packets are used to route data from one component directly to a certain
other component. The structure for this packet, as sent by the client, consists
of a string "to" that names the target component, a "data" entry which contains
arrays and hashes and data oh my! (see structures.md), and an optional "id"
entry that is used for not much at all. The server adds a "from" entry that
tells the receiver who sent the packet and also sets the "id" entry to nil if it
doesn't exist already. The server will also add a "shorturl" entry to the root
data structure if it contains a "url" entry. The final packet is then sent to
the target with the action "private".

### publish
Published packets are used to route data from one component to any and all
subscribers of a certain channel. The structure for this packet is the same as
the "private" packet, except that it has "channel" instead of "to", and there
is no "id" entry. The note about "shorturl" from private applies here as well.
