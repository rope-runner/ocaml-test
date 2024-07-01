open Lwt.Infix
open Lwt_unix
open Random

let address = Unix.inet_addr_loopback
let port = 54321
let min_message_lifetime = 5
let max_message_lifetime_surrplus = 16
let min_process_lifetime = 60
let max_process_lifetime_surrplus = 61

let rec send_alive_message oc =
  Random.self_init();
  let interval = min_message_lifetime + Random.int max_message_lifetime_surrplus in 
  Lwt_unix.sleep (float_of_int interval) >>= fun () ->
  Lwt_io.write_line oc "I'm alive" >>= fun () ->
  send_alive_message oc

let rec self_destruct () =
  let interval = min_process_lifetime + Random.int max_process_lifetime_surrplus in
  Lwt_unix.sleep (float_of_int interval) >>= fun () ->
  exit 0

let connect_to_tcp_server () =
  let sockaddr = ADDR_INET (address, port) in
  let socket = socket PF_INET SOCK_STREAM 0 in
  Lwt_io.printf "Child process attempting to connect to server\n" >>= fun () ->
  connect socket sockaddr >>= fun () ->
  let ic = Lwt_io.of_fd ~mode:Lwt_io.Input socket in
  let oc = Lwt_io.of_fd ~mode:Lwt_io.Output socket in
  Lwt_io.printf "Child process connected to server\n" >>= fun () ->
  let rec listen () =
    Lwt_io.read_line_opt ic >>= function
    | Some line ->
      let response = string_of_int (String.length line) in
      Lwt_io.write_line oc response >>= listen
    | None -> 
      Lwt_io.printf "Server closed the connection\n"
  in
  Lwt.async (fun () -> send_alive_message oc);
  Lwt.async (fun () -> self_destruct ());
  listen ()

let main () =
  Lwt_main.run (connect_to_server ())

let () = main ()
