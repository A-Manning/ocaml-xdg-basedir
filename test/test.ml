(********************************************************************************)
(*  xdg-basedir: XDG basedir location for data/cache/configuration files        *)
(*                                                                              *)
(*  Copyright (C) 2011, OCamlCore SARL                                          *)
(*  Copyright (C) 2021, O(1) Labs LLC                                           *)
(*                                                                              *)
(*  This library is free software; you can redistribute it and/or modify it     *)
(*  under the terms of the GNU Lesser General Public License as published by    *)
(*  the Free Software Foundation; either version 2.1 of the License, or (at     *)
(*  your option) any later version, with the OCaml static compilation           *)
(*  exception.                                                                  *)
(*                                                                              *)
(*  This library is distributed in the hope that it will be useful, but         *)
(*  WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY  *)
(*  or FITNESS FOR A PARTICULAR PURPOSE. See the file COPYING.txt for more      *)
(*  details.                                                                    *)
(*                                                                              *)
(*  You should have received a copy of the GNU Lesser General Public License    *)
(*  along with this library; if not, write to the Free Software Foundation,     *)
(*  Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301 USA               *)
(********************************************************************************)

open OUnit
open FileUtil
open FilePath
open XDGBaseDir

let mk_tmpdir () = 
 let tmpdir = 
   Filename.temp_file "xdg-basedir" ".dir"
 in
   rm [tmpdir];
   mkdir tmpdir;
   tmpdir

let bracket_xdg_env f = 
  bracket
    (fun () ->
       mk_tmpdir (),
       mk_tmpdir (),
       mk_tmpdir ())
    (fun (home, sys1, sys2) ->
       let mk_fn = make_filename in
       let xdg_env =
         { cache_home = mk_fn [home; ".cache"];
           config_home = mk_fn [home; ".config"];
           config_dirs = [ mk_fn [sys1; "etc"];
                           mk_fn [sys2; "etc"]];
           data_dirs = [ mk_fn [sys1; "share"];
                         mk_fn [sys2; "share"] ];
           data_home = mk_fn [home; ".local"; "share"];
           runtime_dir = None;
           state_home = mk_fn [home; ".local"; "state"];
         }
       in
         f xdg_env)
    (fun (dn1, dn2, dn3) ->
       rm ~recurse:true [dn1; dn2; dn3])

let test_of_vector (nm, user_file, all_files) = 
  nm>::
  bracket_xdg_env
    (fun xdg_env ->
       let xdg_env = 
         Some xdg_env
       in
       let fn = 
         user_file ?xdg_env ?exists:(Some false) "test.data"
       in
       let assert_all_files ~msg exp = 
         assert_equal 
           ~msg
           ~printer:(String.concat "; ")
           exp
           (all_files ?xdg_env ?exists:(Some true) "test.data")
       in
         assert_raises
           ~msg:"user file doesn't exist"
           Not_found
           (fun () ->
              user_file ?xdg_env ?exists:(Some true) "test.data");
         assert_all_files
           ~msg:"nothing"
           [];
         mkdir_openfile touch fn;
         assert_all_files
           ~msg:"1 file"
           [fn])

let tests = 
  "XDGBaseDir">:::
  (List.map test_of_vector 
    [ "cache_home", 
      Cache.user_file, 
      (fun ?xdg_env ?exists fn -> 
        try 
          [Cache.user_file ?xdg_env ?exists fn]
        with Not_found ->
          []);

      "config_home", 
      Config.user_file, 
      Config.all_files;

      "data_home", 
      Data.user_file, 
      Data.all_files;

      "state_home", 
      State.user_file, 
      (fun ?xdg_env ?exists fn -> 
        try 
          [State.user_file ?xdg_env ?exists fn]
        with Not_found ->
          []);
      ])

let _ =
  run_test_tt_main tests
