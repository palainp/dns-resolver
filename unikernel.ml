(* (c) 2017, 2018 Hannes Mehnert, all rights reserved *)
open Lwt.Infix

let src = Logs.Src.create "memory" ~doc:"Memory monitor"
module Log = (val Logs.src_log src : Logs.LOG)

let wordsize_in_bytes = Sys.word_size / 8

module Main (R : Mirage_random.S) (P : Mirage_clock.PCLOCK) (M : Mirage_clock.MCLOCK) (T : Mirage_time.S) (S : Mirage_stack.V4V6) = struct
  module D = Dns_resolver_mirage.Make(R)(P)(M)(T)(S)

  let report_mem_usage =
    Lwt.async (fun () ->
      let rec aux () =
        let stats = Solo5_os.Memory.stat () in
        let { Solo5_os.Memory.free_words; heap_words; _ } = stats in
        let mem_total = heap_words * wordsize_in_bytes in
        let mem_free = free_words * wordsize_in_bytes in
        let quick_stat = Solo5_os.Memory.quick_stat () in
        let { Solo5_os.Memory.free_words; heap_words; _ } = quick_stat in
        let top_heap = free_words * wordsize_in_bytes in
        Log.info (fun f -> f "Memory usage: We have %a above top_heap / free %a / total %a"
          Fmt.bi_byte_size top_heap
          Fmt.bi_byte_size mem_free
          Fmt.bi_byte_size mem_total);
        T.sleep_ns (Duration.of_f 10.0) >>= fun () ->
        aux ()
      in
      aux ()
    )

  let start _r _pclock _mclock _ s =
    report_mem_usage ;
    let now = M.elapsed_ns () in
    let server =
      Dns_server.Primary.create ~rng:R.generate Dns_resolver_root.reserved
    in
    let p = Dns_resolver.create now R.generate server in
    D.resolver ~timer:1000 ~root:true s p ;
    S.listen s
end
