(* mirage >= 4.5.0 & < 4.6.0 *)
(* (c) 2017, 2018 Hannes Mehnert, all rights reserved *)

open Mirage

let with_dnssec = runtime_arg ~pos:__POS__ "Unikernel.with_dnssec"

let dns_handler =
  let packages =
    [
      package "logs";
      package "dns" ~min:"6.4.1" ~max:"7.4.0";
      package "dns-server" ~min:"6.4.1" ~max:"7.4.0";
      package "dns-mirage" ~min:"6.4.1" ~max:"7.4.0";
      package "dnssec" ~min:"6.4.1" ~max:"7.4.0";
      package ~sublibs:[ "mirage" ] "dns-resolver" ~min:"6.4.1" ~max:"7.4.0";
    ]
  in
   main
    ~runtime_args:[ with_dnssec; ]
    ~packages
    "Unikernel.Main" (random @-> pclock @-> mclock @-> time @-> stackv4v6 @-> job)

let () =
  register ~reporter:no_reporter "resolver" [dns_handler $ default_random $ default_posix_clock $ default_monotonic_clock $ default_time $ generic_stackv4v6 default_network ]
