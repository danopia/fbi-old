import structs/[List, ArrayList]

import net/StreamSocket
import Socket

import Packets

Client: class {
  name, secret, server: String
  port: Int
  channels: ArrayList<String>
  
  socket: StreamSocket
  reader: BufferedSocketReader
  writer: StreamSocketWriter

  init: func (=name, =secret, =server, =port, =channels) {
    socket = StreamSocket new(server, port)
    reader = BufferedSocketReader new(socket)
    writer = socket writer()
  }

  connect: func {
    socket connect()
    onConnect()
  }

  run: func {
    connect()
    while(true) {
      line := reader readLine()
      handleLine(line)
    }
    socket close()
  }

  handleLine: func (line: String) {
    pkt := Packet new(this, line)
    
    onAll(pkt)
    
    match(pkt action) {
    
      case "welcome" =>
        onWelcome(Welcome new(pkt))
        
      case "auth" =>
        onAuth(Auth new(pkt))
        
      case "subscribe" =>
        onSubscribe(Subscribe new(pkt))
        
      case "publish" =>
        onPublish(Publish new(pkt))
        
      case =>
        onUnhandled(pkt)
    }
  }
  
  send: func (pkt: Packet) {
    onSend(pkt)
    writer write(pkt toString() + "\r\n")
  }
  

  // Callbacks
  onConnect: func {}

  onSend: func (pkt: Packet) {}

  onAll: func (pkt: Packet) {}

  onUnhandled: func (pkt: Packet) {}
  
  
  
  onWelcome: func (pkt: Welcome) {
    Auth new(this, this name, this secret) send()
  }
  
  onAuth: func (pkt: Auth) {
    Subscribe new(this, this channels) send()
  }
  
  onSubscribe: func(pkt: Subscribe) {}
    
    onPublish: func(pkt: Publish) {}
}
