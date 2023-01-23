{.hint[name]: off.}
import std/net

const CATIT_HEADER: array[4, uint8] = [0x00'u8, 0x00, 0x55, 0xAA]

type Message {.packed.} = object
  header: array[4, uint8]
  pad00: uint16
  first_counter: uint16
  unk00: uint32
  unk01: uint32
  version: array[4, char]
  unk02: uint32
  unk03: uint16
  day_counter: uint16
  unk_rest: array[27, uint8]

static: assert sizeof(Message) == 55, "The size of the message is incorrect."

proc default(msg: var Message) =
  msg.header = CATIT_HEADER
  msg.pad00 = 0
  # This is a counter that's always incrementing too, but you don't need to
  # change it for the feeder to detect it.
  msg.first_counter = 0xC6_05

  # unknown fixed value, this value doesn't change neither by days nor number
  # of messages.
  msg.unk00 = 0x0D_00_00_00
  # Same as unk00
  msg.unk01 = 0x27_00_00_00

  # Version of the communication protocol I'd guess.
  msg.version = ['3', '.', '3', '\x00']

  # In all cases, always 0
  msg.unk02 = 0
  msg.unk03 = 0

  # This is the counter of how many foods have been served during the day.
  msg.day_counter = 69

  # We still need to figure out what this bytes are.
  # I suspect is related to the date, because when I triggered subsequent
  # messages, only one byte changed, but comparing it to another packet from
  # days ago most of the bytes were different.
  msg.unk_rest = [0x0E'u8, 0x10, 0x3E, 0x62, 0xDE, 0xC3, 0x1C, 0x37, 0x54, 0x7B, 0x00, 0xFA, 0x52, 0xCE, 0xE6, 0x59, 0xA6, 0x36, 0xD8, 0xFC, 0x27, 0xE2, 0x73, 0x00, 0x00, 0xAA, 0x55]


proc main() =

  # First we listen to the machine to advertise itself. It sends a packet
  # through the port 6667 very often to keep it alive. We only need to check
  # for the header to be the bytes we want.
  let socket = new_socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
  socket.bind_addr(Port(6667))

  var
    data: string
    ip: string
    port: Port

  echo "[-] Searching for the Catit Feeder"
  while true:
    discard socket.recv_from(data, 1024, ip, port)
    echo "[-] Data received from ", ip
    if data.toOpenArrayByte(0, 3) == CATIT_HEADER.toOpenArray(0, 3):
      echo "[*] Catit Feeder found! ip: ", ip
      break

  # Now we have the IP of the Catit, so we can send our own message :)
  let out_socket = new_socket()
  out_socket.connect(ip, Port(6668))

  var msg = Message()
  msg.default()

  echo "[-] Sending data"
  discard out_socket.send(msg.addr, sizeof(msg))
  echo "[*] Data was sent correctly, enjoy :)"

when isMainModule:
  main()
