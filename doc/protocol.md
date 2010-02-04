FBI uses a pretty simple protocol as a base. All data transfers (aka packets)
are in a hash/array format, which is transmitted as JSON. The encoded JSON text
can *NOT* have any raw newlines in it. Each JSON string is terminated with a
unix-style "\n" line ending (the official server will accept Windows-style
"\r\n" line endings but will only send packets back with a "\n" termination).

The JSON hash must have an "action" entry at its root. The action entry is used
to determine what the packet is for, and may be referred to as the packet's
command. The rest of the hash is not defined in this protocol document.

For information on the different actions, see actions.md. For information on the
different hash structures that you will see when using FBI, see structures.md.
