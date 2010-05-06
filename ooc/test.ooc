import net/StreamSocket, structs/ArrayList

use yajl
import yajl/Yajl // into JSON

import Component, Packets

TestComponent: class extends Client {
    init: func ~TestComponent (.name, .secret, .server, .port, .channels) {
        super(name, secret, server, port, channels)
    }

    onSend: func (pkt: Packet) {
        ">> " print()
        pkt toString() println()
    }

    onAll: func (pkt: Packet) {
        "<< " print()
        pkt toString() println()
    }
    
    
    onWelcome: func (pkt: Welcome) {
        "Got welcomed by %s at %s" format(pkt server_name, pkt origin) println()
        super(pkt)
    }
    
    onAuth: func (pkt: Auth) {
        "Authed to the server as %s" format(pkt username) println()
        super(pkt)
    }
    
    onSubscribe: func (pkt: Subscribe) {
      "Subscribed to %i channels: %s" format(pkt channels size, pkt channels join(", ")) println()
      super(pkt)
    }
    
    onPublish: func (pkt: Publish) {
      // "Got packet from %s to %s: %s" format(pkt origin, pkt target, generate(pkt data)) println()
      if (pkt target == "#irc" && pkt data contains("channel")) {
        channel := pkt data getValue("channel", Int)
        message := pkt data getValue("message", String)
        
        if (message contains("FBI")) {
          reply := Publish new(this, "#irc")
          reply data["mode"] = "message"
          reply data["channel_id"] = channel
          reply data["message"] = "That's me!"
          reply send()
        }
      }
    }
    
    onUnhandled: func (pkt: Packet) {
        "<< " print()
        pkt toString() println()
    }
}

main: func {
    client := TestComponent new("test client", "hil0l", "danopia.net", 5348, ["#irc", "#mail"])
    client run()
}
