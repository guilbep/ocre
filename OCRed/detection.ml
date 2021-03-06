(*
	OCRe - The ultimate OCR - HUGE Software
	OCRe is a project developed by 2nd year EPITA students
	- website: http://huge.ocre.free.fr/
	- svn repository: http://code.google.com/p/ocre

	About this folder:	OCRed
		OCRed is the preprocessing part of OCRe.
	About this file:	OCRed/detection.ml
		This is the detection.ml file.
*)
let proj_h_table = ref (Transforme.bigarray1 1)
let average = ref 0

let projection_h tableau =
  let x = Bigarray.Array2.dim1 tableau in
  let y = Bigarray.Array2.dim2 tableau in
    proj_h_table := Transforme.bigarray1 y;
    for i = 0 to (y - 1) do
      begin
        let j = ref 0 in
        while (!j < x) && (
          (Bigarray.Array2.get tableau !j i) >=
            (Int32.of_int 255)) do
            begin
              j := !j + 1;
            end
          done;
        Bigarray.Array1.set
          !proj_h_table
          (i)
          (Int32.of_int(!j));
      end
    done

let proj_and_average tableau =
  let x = Bigarray.Array2.dim1 tableau in
  let y = Bigarray.Array2.dim2 tableau in
    proj_h_table := Transforme.bigarray1 y;
    for i = 0 to (y - 1) do
      begin
        let j = ref 0 in
        while (!j < x) && (
          (Bigarray.Array2.get tableau !j i) >=
            (Int32.of_int 255)) do
            begin
              j := !j + 1;
            end
          done;
        Bigarray.Array1.set
          !proj_h_table
          (i)
          (Int32.of_int(!j));
        average := !average + !j;
      end
    done;
    average := (!average / y)


(*subfunction for take_coef ... thanks to the "norme" *)

(* wrapper of base functions for manipulating int string float *)
let foi x = float_of_int x
let iof x = int_of_float x
let ito32 x = Int32.of_int x
let io32 x = Int32.to_int x
let soi x = string_of_int x
let sof x = string_of_float x

(* return the value of the box i in the table x ; Int32*)
let get x i   = Bigarray.Array1.get x i

(* return the length of the table x *)
let dim x     = Bigarray.Array1.dim x

(* refresh the sum of the coef director*)
let refresh_coefs tab i j nbr_coefs sum_coefs filter_d filter_u =
  let a = foi(!i) in
  let b = foi(!j) in
  let fa = foi(io32(get tab !i)) in
  let fb = foi(io32(get tab !j)) in
    if ((b -. a) <> (0.)) && ((fb -. fa)<> (0.)) then
      begin
        let current_coef = (fb -. fa) /. (b -. a) in
          if ( 10. < abs_float(current_coef)) &&
            (abs_float(current_coef) < 200. ) then
              begin
                sum_coefs := !sum_coefs +. current_coef;
(*                 print_string(sof(current_coef)^" "^ *)
(*                                soi(!nbr_coefs)^"coefs\n"); *)
                nbr_coefs := !nbr_coefs + 1;
              end
      end


(* send to the future of your world -_avoid the bounds_-*)
let til_not_bound tab bound pos =
  let i = ref (io32(get tab !pos)) in
    while (!i = bound) && (!pos < ((dim tab))) do
      begin
        pos := !pos + 1;
        i := io32(get tab !pos);
      end
    done

(* send you where you're  upon the average *)
let after_average tab pos =
  let i = ref (io32(get tab !pos)) in
    while (!i <= !average) && ((!pos+1) < ((dim tab) -1)) do
      begin
        pos := !pos + 1;
        i := io32(get tab !pos);
      end
    done

(* send you where you're below the average *)
let before_average tab pos =
  let i = ref (io32(get tab !pos)) in
    while (!i >= !average) && (!pos < ((dim tab) -1)) do
      begin
        pos := !pos + 1;
        i := io32(get tab !pos);
      end
    done

(* we don't really know why, but we know we have to*)
let check_position_start tab pos =
  if (io32(get tab !pos) > !average) then
    before_average tab pos
  else
    after_average tab pos


(* when you're bent on the righ, i is the current position j have to be
   initiated  before the call of the function*)
let find_high_r tab i j boundup bounddown =
  let gett i    = io32 (get tab i) in
  let tabi      = gett !i in
(*       print_string(soi(boundup)^" ceci est le boundup \n"); *)
    while
(*       print_string(soi(!j)^" ceci est le i \n"); *)
      (*je plante la*)
      ((!j + 1 ) < (boundup)) &&
      ((!j + 1 ) > (bounddown)) &&
      (gett (!j + 1 ) >= tabi)
    do
      begin
        j := !j + 1;
      end
    done

(* when you're bent on the left, i is the current position j have to be
   initiated  before the call of the function*)
let find_high_l tab i j boundup bounddown =
  let gett i    = io32(get tab i) in
  let tabi      = gett !i in
    while
      ((!j + 1 ) < boundup) &&
      ((!j + 1 ) > bounddown) &&
      (gett (!j + 1 ) < tabi)
    do
      begin
(*         print_string(soi(!j)^" ceci est mon j\n"); *)
        j := !j + 1;
      end
    done

(* filter_d et _u ar equivalent to filter down and up*)
let bent_right tab i nbr_coefs sum_coefs filter_d filter_u =
  let j = ref !i in
  let len = dim tab in
(*     print_string(soi(len)^" this is len PROUTbeforeafind\n"); *)
    find_high_r tab i j (len - 1) 0;
(*     print_string("PROUTafterfind\n"); *)
    refresh_coefs tab i j nbr_coefs sum_coefs filter_d filter_u;
    (* it would be <= 209*)
    i := !j + 1;
(*     print_string("PROUTbeforetil\n"); *)
    til_not_bound tab (len -1) i;
(*     print_string("PROUTaftertil\n"); *)
    if (io32(get tab !i) < !average) then
      begin
(*         print_string("PROUT1\n"); *)
        after_average tab i;
(*         print_string("PROUT2\n"); *)
      end
    else
      begin
(*         print_string("PROUT3\n"); *)
        before_average tab i; (* may have a probleme*)
(*         print_string("PROUT4\n"); *)
      end

(* filter_d et _u ar equivalent to filter down and up*)
let bent_left tab i nbr_coefs sum_coefs filter_d filter_u =
  let j = ref !i in
  let len = dim tab in
    find_high_l tab i j (len - 1) 0;
    (* it would be <= 209*)
    refresh_coefs tab i j nbr_coefs sum_coefs filter_d filter_u;
    i := !j + 1;
    til_not_bound tab (len -1) i;
    if (io32(get tab !i) < !average) then
      after_average tab i
    else
      before_average tab i (* may have a probleme*)

(* thank you captain obvious *)
let detect_angle () =
  Seuil.seuillage  !Surface.image;
  Interpolation.resize_for_disco !Surface.image;
  proj_and_average !Surface.reduce;
  let bound = Bigarray.Array2.dim1 !Surface.reduce in
    (* algo principale*)
  let i = ref 0 in
    til_not_bound !proj_h_table 0 i;
    til_not_bound !proj_h_table bound i;
    after_average !proj_h_table i;
    before_average !proj_h_table i;
    (*     check_position_start !proj_h_table i; *)
    let j = ref (!i + 1) in
    let droite = ref false in
    let somcoef = ref 0. in
    let nbrscoef = ref 0 in
    let gett x = io32(get !proj_h_table x) in
    while (gett !i)  = (gett !j) do
      j := !j + 1;
    done;
    if (gett !i) < (gett !j) then
      droite := true;
    if !droite then
      begin
        while (!i < ((dim !proj_h_table) - 1)) do
          bent_right !proj_h_table i nbrscoef somcoef 4. 60.;
        done;
      end
    else
      begin
(*         print_string(soi((dim !proj_h_table) - 1)^"dimtab\n"); *)
        while (!i < ((dim !proj_h_table) - 1)) do
          bent_left !proj_h_table i nbrscoef somcoef 4. 60.;
        done;
      end;
    let pente = (!somcoef /. foi(!nbrscoef)) in
(*       print_string(sof(!somcoef)^" ceci est ma somcoef\n"); *)
(*       print_string(soi(!nbrscoef)^" ceci est mon nbrcoef\n"); *)
(*       print_string(sof(pente)^" ceci est ma pente\n"); *)
      let alpha = ref 0. in
        if (pente < 0.) then
          alpha := ~-.(90. +. (atan(pente)*.(180./.(3.14159265))))
        else
          alpha := (90. -. (atan(pente)*.(180./.(3.14159265))));
(*         print_string(sof(!alpha)^" ceci est mon angle\n"); *)
        Surface.image := Rotation.optimized2 !Surface.image
          (!alpha*.(3.14159265/.180.))

(* use to have a .csv file*)
let histo_to_file file =
  let chan = (open_out file) in
    for i = 0 to ((Bigarray.Array1.dim !proj_h_table) -1) do
      begin
        let str = (
          Int32.to_string(Bigarray.Array1.get !proj_h_table i)^
            " \n\n"
        ) in
          output chan (str) 0 ((String.length str) -1);
      end
    done;
    close_out chan

