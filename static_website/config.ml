open Mirage

(* If the Unix `MODE` is set, the choice of configuration changes:
   MODE=crunch (or nothing): use static filesystem via crunch
   MODE=fat: use FAT and block device (run ./make-fat-images.sh)
 *)
let fs =
  let mode = try match String.lowercase (Unix.getenv "FS") with
    | "fat" -> `Fat
    | _     -> `Crunch
    with Not_found -> `Crunch
  in
  let fat_ro dir = kv_ro_of_fs (fat_of_files ~dir ()) in
  match mode with
  | `Fat    -> fat_ro "./htdocs"
  | `Crunch -> crunch "./htdocs"

let stack console =
  let net =
    try match Sys.getenv "NET" with
      | "direct" -> `Direct
      | "socket" -> `Socket
      | _        -> `Direct
    with Not_found -> `Direct
  in
  let dhcp =
    try match Sys.getenv "DHCP" with
      | "" -> false
      | _  -> true
    with Not_found -> false
  in
  match net, dhcp with
  | `Direct, true  -> direct_stackv4_with_dhcp console tap0
  | `Direct, false -> direct_stackv4_with_default_ipv4 console tap0
  | `Socket, _     -> socket_stackv4 console [Ipaddr.V4.any]

let port =
  try match Sys.getenv "PORT" with
    | "" -> 80
    | s  -> int_of_string s
  with Not_found -> 80

let server =
  http_server port (stack default_console)

let main =
  foreign "Unikernel.Main" (console @-> kv_ro @-> http @-> job)

let () =
  add_to_ocamlfind_libraries ["re.str"];
  add_to_opam_packages ["re"];

  register "www" [
    main $ default_console $ fs $ server
  ]
