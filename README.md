# OSerial
OCaml Serial Module

## Installation
```
opam install serial
```
## Usage
Create a Serial_config module
```ocaml
module Serial_config = struct
    let baud_rate = 115200
end
```

Open the port
```ocaml
module Serial0 = Serial.Make(Serial_config)

let () =
    Lwt_main.run (Serial0.connect "/dev/ttyUSB0")
```

**Supplied Functions**
The function returns are wrapped in `Lwt.t`, so please read up on [Lwt](https://ocsigen.org/lwt/5.2.0/manual/manual) should you be unfamiliar with the library.
```ocaml
read_line : unit -> string Lwt.t
write_line : string -> unit Lwt.t
```
```ocaml
set_baud_rate : int -> unit Lwt.t
```
Useful should you wish to change the baud rate after opening the connection.
```ocaml
wait_for_line : string -> unit Lwt.t
```
Usage: `wait_for_line "READY"`.
Currently waits forever if the keyword is not received.
```ocaml
io_loop : string option -> unit Lwt.t
```
Opens a two-way communication channel between stdin and the serial device.
Usage: `io_loop (Some "quit")`.
If `None` is supplied instead, does not exit for any keyword.
