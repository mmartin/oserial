(** Configuration for opening a Serial connection *)
module type Serial_config_type = sig
	(** Connection Baud rate *)
	val baud_rate : int
end

(** Main module *)
module type Serial_type = sig
	(** Submodule for values that should not be used externally *)
	module Private : sig
		type connection =
			{ fd: Lwt_unix.file_descr
			; in_channel: Lwt_io.input Lwt_io.channel
			; out_channel: Lwt_io.output Lwt_io.channel
			}

		val state : connection option ref
	end

	val connect : string -> unit Lwt.t

	val set_baud_rate : int -> unit Lwt.t

	val flush : unit -> unit Lwt.t

	val read_line : unit -> string Lwt.t
	val write_line : string -> unit Lwt.t
	val write_bytes : bytes -> unit Lwt.t

	(** Wait for the specified string to be received.
	{b Warning:} currently waits indefinitely. *)
	val wait_for_line : string -> unit Lwt.t

	(** Open two-way communication between std(i/o) and the Serial device.

	Supply [Some "$KEYWORD"] to exit the loop upon entering the specified
	line in stdin. Supplying [None] causes this function to loop indefinitely. *)
	val io_loop : string option -> unit Lwt.t
end
