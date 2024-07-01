open Lwt.Infix
open Lwt_unix

let address = Unix.inet_addr_loopback
let port = 54321

let clients = ref []
let running_processes = ref []

let write_log message =
  let timestamp = Unix.gettimeofday () |> Unix.gmtime in
  let datetime = Printf.sprintf "%04d-%02d-%02d %02d:%02d:%02d"
    (1900 + timestamp.tm_year) (timestamp.tm_mon + 1) timestamp.tm_mday
    timestamp.tm_hour timestamp.tm_min timestamp.tm_sec in
  let log_entry = Printf.sprintf "%s, Time: %s" message datetime in
  Lwt_io.with_file ~mode:Lwt_io.Output ~flags:[O_WRONLY; O_APPEND; O_CREAT] "log.txt"
    (fun oc -> Lwt_io.write_line oc log_entry)

let handle_tcp_connection ic oc =
  clients := (ic, oc) :: !clients;
  let rec listen () =
    Lwt_io.read_line_opt ic >>= function
    | Some line ->
      (if line = "I'm alive" then
        write_log "I'm alive"
       else
        write_log ("Length: " ^ line))
    | None -> 
      clients := List.filter (fun (c_ic, _) -> c_ic != ic) !clients;
      Lwt.return_unit
  in
  listen ()

let create_server () =
  let sockaddr = ADDR_INET (address, port) in
  let srv_socket = socket PF_INET SOCK_STREAM 0 in
  bind srv_socket sockaddr >>= fun () ->
  listen srv_socket 10;
  Lwt_io.printf "Server listening on %s:%d\n" (Unix.string_of_inet_addr address) port >>= fun () ->
  let rec accept_loop () =
    accept srv_socket >>= fun (client_socket, _client_addr) ->
    let ic = Lwt_io.of_fd ~mode:Lwt_io.Input client_socket in
    let oc = Lwt_io.of_fd ~mode:Lwt_io.Output client_socket in
    Lwt.async (fun () -> handle_tcp_connection ic oc);
    accept_loop ()
  in
  accept_loop ()

let rec read_from_std () =
  Lwt_io.read_line_opt Lwt_io.stdin >>= function
    | Some line ->
      Lwt_list.iter_p (fun (_ic, oc) ->
        Lwt_io.write_line oc line >>= fun () ->
        Lwt_io.printf "Sent to client: %s\n" line
      ) !clients >>= fun () ->
      read_from_std ()
    | None -> Lwt.return_unit

let spawn_child_process () =
  let process =
    Lwt_process.open_process_none
      ("./client", [| "client" |])
  in
  running_processes := process :: !running_processes;
  Lwt.return process

let rec child_processes_health_check () =
  Lwt_unix.sleep 1.0 >>= fun () ->
  let rec check_processes = function
    | [] -> Lwt.return_unit
    | process :: rest ->
      (match process#state with
       | Lwt_process.Running -> check_processes rest
       | Lwt_process.Exited _ ->
         write_log "Respawned child process" >>= fun () ->
         running_processes := List.filter ((!=) process) !running_processes;
         spawn_child_process () >>= fun _ -> check_processes rest)
  in
  check_processes !running_processes >>= child_processes_health_check

let spawn_child_processes n =
  Lwt_list.map_s (fun _ -> spawn_child_process ()) (List.init n (fun x -> x))

let main () =
  let n = if Array.length Sys.argv > 1 then int_of_string Sys.argv.(1) else 5 in
  spawn_child_processes n >>= fun _ ->
  Lwt.join [
    create_server ();
    read_from_std ();
    child_processes_health_check ()
  ]

let () = Lwt_main.run (main ())
