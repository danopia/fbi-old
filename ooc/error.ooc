use yajl
import yajl/Yajl // into JSON

main: func {
  packet := parse("{\"mode\":\"test\"}", ValueMap)
  value := packet["mode"]
}
