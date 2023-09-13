(* (c) 2017, 2018 Hannes Mehnert, all rights reserved *)
module Main (R : Mirage_random.S) (P : Mirage_clock.PCLOCK) (M : Mirage_clock.MCLOCK) (T : Mirage_time.S) (S : Tcpip.Stack.V4V6) = struct
  module D = Dns_resolver_mirage.Make(R)(P)(M)(T)(S)

  open Lwt

  let src = Logs.Src.create "memory_pressure" ~doc:"Memory pressure monitor"
  module Log = (val Logs.src_log src : Logs.LOG)

  let wordsize_in_bytes = Sys.word_size / 8

  let fraction_free stats =
    let { Solo5_os.Memory.free_words; heap_words; _ } = stats in
    float free_words /. float heap_words

  let print_mem_usage =
    let rec aux () =
      let stats = Solo5_os.Memory.quick_stat () in
      let { Solo5_os.Memory.free_words; heap_words; _ } = stats in
      let mem_total = heap_words * wordsize_in_bytes in
      let mem_free = free_words * wordsize_in_bytes in
      Log.err (fun f -> f "Memory usage: free %d / %d (%.2f %%)"
        mem_free
        mem_total
        (fraction_free stats *. 100.0));
      Solo5_os.Time.sleep_ns (Duration.of_f 1.0) >>= fun () ->
      aux ()
    in
    aux ()

  let start _r _pclock _mclock _ s =
    let now = M.elapsed_ns () in
    let server =
      Dns_server.Primary.create ~rng:R.generate Dns_resolver_root.reserved
    in
    let p = Dns_resolver.create ~dnssec:(Key_gen.with_dnssec ()) now R.generate server in
    D.resolver ~timer:1000 ~root:true s p ;
    Lwt.pick [ S.listen s ; print_mem_usage]
end
