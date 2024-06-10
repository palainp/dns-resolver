(* (c) 2017, 2018 Hannes Mehnert, all rights reserved *)
open Cmdliner
open Lwt

let with_dnssec =
  let doc = Arg.info ~doc:"Use DNSSEC when it's possible to resolve domain-names." [ "with-dnssec" ] in
  Arg.(value & opt bool false doc)

module Main (R : Mirage_random.S) (P : Mirage_clock.PCLOCK) (M : Mirage_clock.MCLOCK) (T : Mirage_time.S) (S : Tcpip.Stack.V4V6) = struct
  module D = Dns_resolver_mirage.Make(R)(P)(M)(T)(S)

  let mem_usage =
    Lwt.async (fun () ->
        let rec aux () =
        let wordsize_in_bytes = Sys.word_size / 8 in
        let stats = Solo5_os.Memory.quick_stat () in
        let { Solo5_os.Memory.free_words; heap_words; _ } = stats in
        let mem_total = heap_words * wordsize_in_bytes in
        let mem_free = free_words * wordsize_in_bytes in
        Logs.info( fun f -> f "Meminfo: free %d / %d" mem_free mem_total);
        Solo5_os.Time.sleep_ns (Duration.of_f 300.0) >>= fun () ->
        aux ()
      in
      aux ()
    )

  let start _r _pclock _mclock _ s with_dnssec =
    (* mem_usage ; *)
    let now = M.elapsed_ns () in
    let server =
      Dns_server.Primary.create ~rng:R.generate Dns_resolver_root.reserved
    in
    let p = Dns_resolver.create ~dnssec:with_dnssec now R.generate server in
    D.resolver ~timer:1000 ~root:true s p ;
    S.listen s
end
