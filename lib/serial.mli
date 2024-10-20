open Serial_intf

(** Given a Serial_config struct,
creates a new module with a newly opened Serial connection.
Most programs using the {!Serial} module start with something like:
{[
module Serial_config = struct
	let baud_rate = 115200
end

module Serial0 = Serial.Make(Serial_config)
]}
*)
module Make (T : Serial_config_type) : Serial_type
