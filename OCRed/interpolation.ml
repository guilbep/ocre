(*
	OCRe - The ultimate OCR - HUGE Software
	OCRe is a project developed by 2nd year EPITA students
	- website: http://huge.ocre.free.fr/
	- svn repository: http://code.google.com/p/ocre

	About this folder:	OCRed
		OCRed is the preprocessing part of OCRe.
	About this file:	OCRed/interpolation.ml
		This is the interpolation.ml file.
*)
exception Percentage_too_high
exception Projection_error

let proj_h_table = ref (Transforme.bigarray1 1)

let roundf x = match (modf x) with
  | (x,y) when (x >= 0.5)-> int_of_float(floor(y))
  | (_,y) -> int_of_float(floor(y))
(*
 * PDL
 * cette fonction
 * f(x,y) = (round x, round y)
 *      donne la valeur moyenne en x et y flottant
 * proceder comme la rotation? semble la meilleur solution
 * proceder directement au filtre median?
 *
 * principe: parcourir avec transformation lineaire inverse le tableau
 * de sortie, n'ayant on va se retrouver avec un pixel bizarre essayer
 * la technique du near neighbor, voir filtre bicubique.
 * soit x y l'entree, les sorties sont a b tel que
 * x = gamma a et y = beta b d'ou T^(-1) a = x / gamma et idem pour b
 * la solution est tel que on trouve le x directement a partir de la
 * premiere equation le x et le y seront des floatant qu'on
 * approximera par la methode du near neighbor.
 *
 * gamma = coef sortie x et beta = coef sortie y
 *)
let foi x = float_of_int x
let iof x = int_of_float x
let soi x = string_of_int x
let sof x = string_of_float x

let inverse_resize a b gamma beta=
  (roundf(gamma*.(float_of_int(a))),roundf(beta*.float_of_int(b)))

let is_in_rect x y width height =
  if (x > 0) && (x < width) && (y > 0) && (y <height) then
    true
  else
    false

let resize surf x y =
  let (width,height,pitch) = Surface.dim surf in
    print_string ("height: "^(string_of_int height)^"\n"^"width: "^(string_of_int width)^"\n");
  let gamma = float_of_int(width) /. float_of_int(x) in
  let beta = float_of_int(height) /. float_of_int(y) in
  let my_output = Transforme.bigarray2 x y in
  let my_input = Transforme.surf_to_matrix surf in
    for i=0 to (x - 1) do
      for j=0 to (y - 1) do
        let (a,b) = inverse_resize (i + 1) (j + 1)  gamma beta in
          if (is_in_rect a b height width) then
            begin
              Bigarray.Array2.set
                my_output
                (j)
                (i)
                (Bigarray.Array2.get
                   my_input
                   ( b )
                   ( a ));
            end
           (*  print_string ("a: "^(string_of_int a)^"\n"^"b:  "^(string_of_int b)^"\n\n"); *)
      done;
    done;
  Transforme.matrix_to_surf my_output

let projection_h tableau =
try
  let x = Bigarray.Array2.dim1 tableau in
  let y = Bigarray.Array2.dim2 tableau in
    proj_h_table := Transforme.bigarray1 y;
    for i = 0 to (y - 1) do
      begin
        Bigarray.Array1.set
          !proj_h_table
          (i)
          (Int32.zero);
          for j = 0 to (x -1) do
            begin
              Bigarray.Array1.set
                !proj_h_table
                (i)
                (
                  Int32.add
                    (Bigarray.Array1.get !proj_h_table  i)
                    (if ((Bigarray.Array2.get tableau j i) >
                           Int32.of_int 255) then
                       begin
                         Int32.zero
                       end
                     else
                       begin
                         Int32.of_int 1
                       end
                    )
                )
            end
          done;
      end
    done;
with
  | Projection_error -> print_string ("Maybe we have a wrong table")

let histo_to_file file =
  let chan = (open_out file) in
    for i = 0 to ((Bigarray.Array1.dim !proj_h_table) -1) do
      begin
        let str = (Int32.to_string(Bigarray.Array1.get !proj_h_table i)^" \n\n") in
          output chan (str) 0 ((String.length str) -1);
      end
    done;
    close_out chan

let print_tabh ()=
  let toi x = Int32.to_int x in
  let i2s x = soi(toi(x)) in
    for i = 0 to ((Bigarray.Array1.dim !proj_h_table) -1) do
      begin
        print_string (i2s( (Bigarray.Array1.get !proj_h_table  i))^"; \n")
      end
    done;
    print_string ("\n")

let resize_percent_unit surf percent =
  try
  if (percent > 100) then
    raise Percentage_too_high;
  let p = foi(percent)/.(100.0) in
  let pinv = (100.0)/.foi(percent) in
    print_string ("this is percentage: "^sof(p)^"\n");
    let (width,height,pitch) = Surface.dim surf in
      print_string ("this is height: "^soi(height)^"\n");
        print_string ("this is width: "^soi(width)^"\n");
        let x = roundf(p*.(foi width)) in
        let y = roundf(p*.(foi height)) in
          print_string ("this is newheight: "^soi(y)^"\n");
          print_string ("this is newwidth: "^soi(x)^"\n");
          let my_output = Transforme.bigarray2 (x) (y) in
          let outwidth = Bigarray.Array2.dim1 my_output in
          let outheight = Bigarray.Array2.dim2 my_output in
            print_string ("this is outheight: "^soi(outheight)^"\n");
            print_string ("this is outwidth: "^soi(outwidth)^"\n");
            let my_input = Transforme.surf_to_matrix surf in
              for i=0 to (x - 1) do
                for j=0 to (y - 1) do
                  let (a,b) = inverse_resize (i) (j) (pinv) (pinv) in
                    try
                      Bigarray.Array2.set
                      my_output
                        (i)
                        (j)
                        (Bigarray.Array2.get
                           my_input
                           ( a)
                           ( b));
                    with
                      | Invalid_argument(str) ->
                          print_string
                            (str^
                             " visiblement pour les  valeurs a et  b:\n "^
                             soi(a)^
                             " et "^
                             soi(b)^
                             "\n")
                done;
            done;
              Surface.reduce := my_output;
              (* Transforme.matrix_to_surf my_output; *)
with
  | Percentage_too_high -> print_string ("image non-altere percentage too high\n")
(*       surf *)


let resize_percent surf percent =
  try
  if (percent > 100) then
    raise Percentage_too_high;
  let p = foi(percent)/.(100.0) in
  let pinv = (100.0)/.foi(percent) in
    print_string ("this is percentage: "^sof(p)^"\n");
    let (width,height,pitch) = Surface.dim surf in
      print_string ("this is height: "^soi(height)^"\n");
        print_string ("this is width: "^soi(width)^"\n");
        let x = roundf(p*.(foi width)) in
        let y = roundf(p*.(foi height)) in
          print_string ("this is newheight: "^soi(y)^"\n");
          print_string ("this is newwidth: "^soi(x)^"\n");
          let my_output = Transforme.bigarray2 (x) (y) in
          let outwidth = Bigarray.Array2.dim1 my_output in
          let outheight = Bigarray.Array2.dim2 my_output in
            print_string ("this is outheight: "^soi(outheight)^"\n");
            print_string ("this is outwidth: "^soi(outwidth)^"\n");
            let my_input = Transforme.surf_to_matrix surf in
              for i=0 to (x - 1) do
                for j=0 to (y - 1) do
                  let (a,b) = inverse_resize (i + 1) (j + 1) (pinv) (pinv) in
                    try
                      Bigarray.Array2.set
                      my_output
                        (i)
                        (j)
                        (Bigarray.Array2.get
                           my_input
                           ( a - 1)
                           ( b - 1));
                    with
                      | Invalid_argument(str) ->
                          print_string
                            (str^
                             " visiblement pour les  valeurs a et  b:\n "^
                             soi(a)^
                             " et "^
                             soi(b)^
                             "\n")
                done;
            done;
              Surface.reduce := my_output;
              Transforme.matrix_to_surf my_output
with
  | Percentage_too_high -> print_string ("image non-altere percentage too high\n");
      surf