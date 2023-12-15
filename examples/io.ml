open Lwt.Infix

module Serial_config = struct
	let baud_rate = 115200
end

module Serial0 = Serial.Make(Serial_config)

let () =
	Lwt_main.run begin
		Serial0.connect "/dev/ttyUSB0" >>= fun () ->
		Serial0.io_loop (Some "quit")
	end
