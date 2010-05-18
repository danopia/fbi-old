import text/Buffer
import io/[Reader, Writer]
import net/[StreamSocket, Socket, Address, DNS, Exceptions]

BufferedSocketReader: class extends Reader {
  source: StreamSocket
  buffer: String

  init: func ~BufferedSocketReader (=source) {
    buffer = String new(0)
    marker = 0
  }

  readRaw: func~all -> String {
    return readRaw(source available())
  }

  readRaw: func~withSize(count: Int) -> String {
    string := String new(count)
    source receive(string, count)
    return string
  }

  readMore: func~all -> Int {
    return readMore(source available())
  }

  readMore: func~withSize(max: Int) -> Int {
    string := readRaw(max)
    buffer += string
    return string length()
  }

  readMore!: func -> Int {
    if (this hasNext?)
      return readMore(source available())
    else
      return readMore(1) // can this be, say, 512 to reduce the number of reads while blocking for data?
  }
  
  read: func(chars: String, offset: Int, count: Int) -> SizeT {
    // does this really matter?
    //skip(offset - marker)
    
    while (buffer length() < count) {
      readMore(count - (buffer length()))
    }
    
    chars = buffer substring(0, count)
    buffer = buffer substring(count)
    return chars length()
  }
  
  read: func ~char -> Char {
    if ((buffer length() > 0) || (readMore() > 0)) {
      char_ := buffer first()
      buffer = buffer substring(1)
      return char_
    } else {
      return readRaw(1) first()
    }
  }

  hasNext: func -> Bool {
    source available() > 0
  }
  hasNext?: Bool {
    get { source available() > 0 }
  }
  
  available: Int {
    get { source available() }
  }

  rewind: func(offset: Int) {
    SocketError new("Sockets do not support rewind") throw()
  }

  mark: func -> Long { marker }

  reset: func(marker: Long) {
    SocketError new("Sockets do not support reset") throw()
  }
  
  
  
  readUntil: func (end: Char) -> String {
    while (!buffer contains(end)) readMore!()
    
    string := buffer substring(0, buffer indexOf(end))
    buffer = buffer substring(string length() + 1)
    return string
  }
  
  readUntil: func (end: String) -> String {
    while (!buffer contains(end)) readMore!()
    
    string := buffer substring(0, buffer indexOf(end))
    buffer = buffer substring(string length() + end length())
    return string
  }
}
