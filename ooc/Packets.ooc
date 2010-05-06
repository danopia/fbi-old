import structs/[List, ArrayList]

use yajl
import yajl/Yajl // into JSON

import Component

Packet: class {
  client: Client
  json: ValueMap
  
  init: func (=client, action, origin, target: String) {
    json = ValueMap new()
    
    json["action"] = action
    
    if (origin)
      json["origin"] = origin
    
    if (target)
      json["target"] = target
  }

  init: func ~fromMap (=client, =json) {}

  init: func ~copy (pkt: This) {
    this client = pkt client
    this json = pkt json
  }

  new: static func ~fromString (client: Client, line: String) -> This {
    packet := parse(line, ValueMap)

    This new(client, packet)
  }

  toString: func -> String {
    return generate(this json)
  }

  send: func {
    client send(this)
  }
  
  
  action: String {
    get {
      this json getValue("action", String)
    }
    set(val) {
      this json["action"] = val
    }
  }
  
  origin: String {
    get {
      if (!(this json contains("origin")))
        return null
      
      this json getValue("origin", String)
    }
    set(val) {
      this json["origin"] = val
    }
  }
  
  target: String {
    get {
      if (!(this json contains("target")))
        return null
      
      this json getValue("target", String)
    }
    set(val) {
      this json["target"] = val
    }
  }
  
  
  from_me?: Bool {
    get { this origin == this client name }
  }
  
  to_channel?: Bool {
    get { this target startsWith("#") }
  }
}

Welcome: class extends Packet {
  init: func ~Welcome (.client, server_name: String) {
    super(client, "welcome", null, null)
    
    this server_name = server_name
  }

  init: func ~copy (pkt: Packet) {
    this client = pkt client
    this json = pkt json
  }
  
  
  server_name: String {
    get {
      return this json getValue("name", String)
    }
    set(val) {
      this json["name"] = val
    }
  }
}

Auth: class extends Packet {
  init: func ~Auth (.client, username, secret: String) {
    super(client, "auth", null, null)
    
    this username = username
    this secret = secret
  }

  init: func ~copy (pkt: Packet) {
    this client = pkt client
    this json = pkt json
  }
  
  
  username: String {
    get {
      return this json getValue("user", String)
    }
    set(val) {
      this json["user"] = val
    }
  }
  
  secret: String {
    get {
      if (!(this json contains("secret")))
        return null
      
      this json getValue("secret", String)
    }
    set(val) {
      this json["secret"] = val
    }
  }
}

Subscribe: class extends Packet {
  init: func ~Subscribe (.client, channels: ArrayList<String>) {
    super(client, "subscribe", null, null)
    
    this channels = channels
  }

  init: func ~copy (pkt: Packet) {
    this client = pkt client
    this json = pkt json
  }
  
  
  channels: ArrayList<String> {
    get {
      list := ArrayList<String> new()
      
      for (elem: Value<String> in (this json getValue("channels", ValueList))) {
        list add(elem value)
      }
      
      return list
    }
    set(val) {
      list := ValueList new()
      
      for (elem: String in val) {
        list addValue(elem)
      }
      
      this json["channels"] = list
    }
  }
}

Publish: class extends Packet {
  init: func ~Publish (.client, target: String, data: ValueMap) {
    super(client, "publish", null, target)
    
    this data = data
  }
  
  init: func ~PublishLazy (.client, target: String) {
    init(client, target, ValueMap new())
  }

  init: func ~copy (pkt: Packet) {
    this client = pkt client
    this json = pkt json
  }
  
  
  data: ValueMap {
    get {
      return this json getValue("data", ValueMap)
    }
    set(val) {
      this json["data"] = val
    }
  }
}
