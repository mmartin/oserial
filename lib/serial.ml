open Serial_intf
open Lwt.Infix
open Lwt.Syntax

module Make (T : Serial_config_type) = struct
	let baud_rate = T.baud_rate

	module Private = struct
		type connection =
			{ fd: Lwt_unix.file_descr
			; in_channel: Lwt_io.input Lwt_io.channel
			; out_channel: Lwt_io.output Lwt_io.channel
			}

		let state : connection option ref = ref None
	end

	let set_baud_rate baud_rate =
		let fd = (Option.get !Private.state).fd in
		(* First get the current attributes, then set them
		 * with baud rate changed *)
		Lwt_unix.tcgetattr fd >>= fun attr ->
		Lwt_unix.tcsetattr fd Unix.TCSANOW
			{ attr with c_ibaud = baud_rate
			; c_obaud = baud_rate
			; c_echo = false
			; c_icanon = false
			; c_igncr = true
			; c_opost = false
			}

	(* Initialize with desired baud rate *)
	let connect port =
		let* fd = Lwt_unix.openfile port [ Unix.O_RDWR; Unix.O_NONBLOCK ] 0o000 in
		(* Here the file permissions are 000 because no file should be created *)
		Private.state := Some
			{ fd
			; in_channel = Lwt_io.of_fd fd ~mode:Lwt_io.input
			; out_channel = Lwt_io.of_fd fd ~mode:Lwt_io.output
			};
		set_baud_rate baud_rate

	let read_line () =
		Lwt_io.read_line (Option.get !Private.state).in_channel

	let flush () = Lwt_io.flush (Option.get !Private.state).out_channel

	let write_line l =
		Lwt_io.fprintl (Option.get !Private.state).out_channel l

	let write_bytes b =
		Lwt_io.write_from_exactly (Option.get !Private.state).out_channel b 0 (Bytes.length b)

	let wait_for_line to_wait_for =
		(* Read from the device until [Some line] is equal to [to_wait_for] *)
		let rec loop = function
		| Some line when line = to_wait_for ->
				Lwt.return ()
		| _ ->
			read_line () >>= fun line ->
			loop (Some line)
		in
		loop None

	(* {{{ IO Loop *)
	let rec io_loop until =

		(* Reads a line from device and outputs to stdout
		 * Keyword is not accepted when received from device; always returns [`Continue] *)
		let read_to_stdin () =
			read_line () >>= fun line ->
			Lwt_io.printl line >>= fun () ->
			Lwt.return `Continue
		in

		(* Reads from stdin and writes to device
		 * If keyword is entered, returns [`Terminate] instead of [`Continue] *)
		let write_from_stdin () =
			Lwt_io.(read_line stdin) >>= function
				| line when Some line <> until ->
						write_line line >>= fun () ->
						Lwt.return `Continue
				| line when Some line = until -> Lwt.return `Terminate
				| _ -> assert false
		in

		(* Take result of first function to complete, and cancel the others *)
		Lwt.pick [read_to_stdin (); write_from_stdin ()] >>= function
		| `Continue -> io_loop until
		| `Terminate -> Lwt.return ()
	(* }}} *)

end
