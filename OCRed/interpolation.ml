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
  let gamma = float_of_int(width) /. float_of_int(x) in
  let beta = float_of_int(height) /. float_of_int(y) in
  let my_output = Transforme.bigarray2 x y in
  let my_input = Transforme.surf_to_matrix surf in
    for i=0 to (y - 1) do
      for j=0 to (x - 1) do
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
          else
            Bigarray.Array2.set
                my_output
                (j)
                (i)
              (Int32.of_int(255));
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
  | Not_found -> print_string ("Maybe we have a wrong table")


(* function wich search for a mount*)
let asom i tab monte descendre count =
  let gett i   = Bigarray.Array1.get tab i in
  let dim x     = Bigarray.Array1.dim x in
  while (!i < (dim tab)) do
    begin
      if(!descendre) then
        begin
          while (!i < ((dim tab) - 1))
            && ((gett !i) >= (gett (!i + 1))) do
              i       := !i + 1
          done;
          monte       := true;
          descendre   := false;
        end
      else
        begin
          while (!i < ((dim tab) - 1))
            && ((gett !i) >= (gett (!i + 1))) do
              i       := !i + 1
          done;
          monte       := false;
          descendre   := true;
          count       := !count + 1;
        end;
      i := !i + 1
    end
  done

(* function wich count the number of mount on the projtable*)
let sommet_of_h tab =
  let i         = ref 0 in
  let count     = ref 0 in
  let monte     = ref false in
  let descendre = ref false in
  let get x i   = Bigarray.Array1.get x i in
  let dim x     = Bigarray.Array1.dim x in
    while ((!i + 1) <= (dim tab -1)) &&
      ((get tab !i) = (get tab (!i + 1))) do
      i := !i + 1
    done;
    if ((!i + 1) <= (dim tab -1)) &&
      ((get tab !i) < (get tab (!i+1))) then
      begin
        monte           := true;
        descendre       := false;
        count           := 0;
      end
    else
      begin
        monte           := false;
        descendre       := true;
        count           := 1;
      end;
    i := !i + 1;
    asom i tab monte descendre count;
    !count

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

let print_tabh () =
  let toi x = Int32.to_int x in
  let i2s x = soi(toi(x)) in
    for i = 0 to ((Bigarray.Array1.dim !proj_h_table) -1) do
      begin
        print_string (i2s( (Bigarray.Array1.get
                              !proj_h_table  i))^"; \n")
      end
    done;
    print_string ("\n")

let resize_percent_unit surf percent =
  try
  if (percent > 100) then
    raise Percentage_too_high;
  let p = foi(percent)/.(100.0) in
  let pinv = (100.0)/.foi(percent) in
  let (width,height,pitch) = Surface.dim surf in
  let x = roundf(p*.(foi width)) in
  let y = roundf(p*.(foi height)) in
  let my_output = Transforme.bigarray2 (x) (y) in
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
  with
    | Percentage_too_high -> print_string (
        "image non-altere percentage too high\n")


let resize_percent surf percent =
  try
  if (percent > 100) then
    raise Percentage_too_high;
  let p = foi(percent)/.(100.0) in
  let pinv = (100.0)/.foi(percent) in
    let (width,height,pitch) = Surface.dim surf in
        let x = roundf(p*.(foi width)) in
        let y = roundf(p*.(foi height)) in
          let my_output = Transforme.bigarray2 (x) (y) in
            let my_input = Transforme.surf_to_matrix surf in
              for i=0 to (x - 1) do
                for j=0 to (y - 1) do
                  let (a,b) = inverse_resize
                    (i + 1) (j + 1) (pinv) (pinv) in
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
                            (str^" visiblement pour les"^
                             " valeurs a et  b:\n "^
                             soi(a)^
                             " et "^
                             soi(b)^
                             "\n")
                done;
            done;
              Surface.reduce := my_output;
              Transforme.matrix_to_surf my_output
with
  | Percentage_too_high -> print_string
      ("image non-altere percentage too high\n");
      surf

let detect_percent_for_rotate surf =
  let surf = Transforme.surf_to_matrix surf in
  let width = Bigarray.Array2.dim1 surf in
    match width with
      | x when (x < 800)  -> 24
      | x when (x < 1200) -> 15
      | x when (x < 2400) -> 8
      | x when (x < 5200) -> 5
      | _ -> 100

let detect_percent surf =
  let surf = Transforme.surf_to_matrix surf in
  let width = Bigarray.Array2.dim1 surf in
    (width/600)

let resize_for_disco surf =
  let perc = detect_percent_for_rotate surf in
    resize_percent_unit surf perc


(*function which for 60 angle send to ouputfile.csv a projection of the
  image rotated *)
let temp_checkangle () =
  Seuil.seuillage !Surface.image;
  resize_for_disco !Surface.image;
  let angle = ref ~-.15. in
    while (!angle <> 15.5) do
      begin
        Surface.rotated :=
          Rotation.optimized3
            !Surface.reduce
            !angle;
        projection_h !Surface.rotated;
        let surf = Transforme.matrix_to_surf !Surface.rotated in
          Sdlvideo.save_BMP
            surf
            (!Path.output^sof(!angle)^".bmp");
          histo_to_file (!Path.output^sof(!angle)^".csv");
          angle := !angle +. 0.5;
      end
    done

(* function which search for a mount*)
let count_hollow tab count =
  let gett i    = Bigarray.Array1.get tab i in
  let dim x     = Bigarray.Array1.dim x in
  let i         = ref 0 in
  let i3        = Int32.of_int(3) in
    while (!i < (dim tab)) do
      begin
        if ((gett !i) > i3) then
          i := !i + 1
        else
          begin
            count := !count + 1;
            i := !i + 1;
          end
      end
    done

(*function which print_out numbers of hollow for each angles*)
let temp_check_hollow () =
  Seuil.seuillage !Surface.image;
  resize_for_disco !Surface.image;
  let count = ref 0 in
  let angle = ref 1.45 in
    while (!angle < 1.7) do
      begin
        Surface.rotated :=
          Rotation.optimized3
            !Surface.reduce
            !angle;
        projection_h !Surface.rotated;
        count_hollow !proj_h_table count;
        print_string(soi(!count)^" is the hollow for an angle of "^sof(!angle)^"\n");
        count := 0;
        angle := !angle +. 0.01;
      end
    done

(* huge function  for dichotomie in search of the angle*)
let fundroite current_sommet next_sommet angle bool prev_angle=
  let pas             = ref ~-.0.1       in
  let prev_sommet     = ref 0           in
    while (!pas <> ~-.0.01) do
      begin
        while (!current_sommet < !next_sommet ) do
          begin
            print_string(string_of_float(!angle)^"\n");
            angle := !angle +. !pas;
            print_string(string_of_float(!angle)^"\n");
            prev_sommet := !current_sommet;
            current_sommet := !next_sommet;
            Surface.rotated :=
              Rotation.optimized3
                !Surface.reduce
                (Rotation.degreef_to_rad (!angle +. !pas));
            projection_h !Surface.rotated;
            next_sommet       := sommet_of_h !proj_h_table;
          end
        done;
        prev_angle := !prev_angle +. !angle;
        angle := 0.;
        if !bool then
          begin
            bool := false;
            pas  := !pas  /. 5.;
          end
        else
          begin
            bool := true;
            pas  := !pas  /. 2.;
          end;
        Surface.rotated :=
          Rotation.optimized3
            !Surface.reduce
            (Rotation.degreef_to_rad (!angle +. !pas));
        projection_h !Surface.rotated;
        next_sommet       := sommet_of_h !proj_h_table;
      end;
    done


let fungauche current_sommet next_sommet angle bool prev_angle =
  let pas               = ref 1.        in
  let prev_sommet       = ref 0         in
    while (!pas <> 0.01) do
      begin
        while (!current_sommet < !next_sommet ) do
          begin
            angle := !angle +. !pas;
            prev_sommet := !current_sommet;
            current_sommet := !next_sommet;
            Surface.rotated :=
              Rotation.optimized3
                !Surface.reduce
                (Rotation.degreef_to_rad (!angle +. !pas));
            projection_h !Surface.rotated;
            next_sommet       := sommet_of_h !proj_h_table;
          end
        done;
        prev_angle := !prev_angle +. !angle;
        angle := 0.;
        if !bool then
          begin
            bool := false;
            pas  := !pas  /. 5.;
          end
        else
          begin
            bool := true;
            pas  := !pas  /. 2.;
          end;
        Surface.rotated :=
          Rotation.optimized3
            !Surface.reduce
            (Rotation.degreef_to_rad (!angle +. !pas));
        projection_h !Surface.rotated;
        next_sommet       := sommet_of_h !proj_h_table;
      end;
    done

let discover_angle surf =
  print_string("avant la boucle infinii je m'aime \n");
  resize_for_disco surf ;
  let prev_angle        = ref 0.        in
  let angle             = ref 0.        in
  let bool              = ref false      in
  let droite            = ref false     in
  let gauche            = ref false     in
    (* c'est comme si on etait a un angle = a 0*)
    projection_h !Surface.reduce;
  let current_sommet    = ref (sommet_of_h !proj_h_table) in
    (* on fait des test pour voir le sens probable de rot*)
    print_string("current_sommet\n");
    Surface.rotated := Rotation.optimized3
      !Surface.reduce
      (Rotation.degreef_to_rad ~-.0.1);
    projection_h !Surface.rotated;
    (* nbres de sommet avec la valeur d'angle de test *)
  let next_sommet       = ref (sommet_of_h !proj_h_table) in
    print_string("next_sommet\n");
    if (!next_sommet < !current_sommet) then
      begin
        gauche := true;
        Surface.rotated := Rotation.optimized3
          !Surface.reduce
          (Rotation.degreef_to_rad 1.);
        projection_h !Surface.rotated;
        next_sommet       := sommet_of_h !proj_h_table;
      end
    else
      begin
        print_string("1 er passage a droite \n");
        print_string(string_of_float(!angle)^"\n");
        droite  := true;
      end;
    print_string("un peu avant la boucle infinii je m'aime \n");
    if(!droite)then
      fundroite current_sommet next_sommet angle bool prev_angle
    else
      fungauche current_sommet next_sommet angle bool prev_angle;
    !prev_angle
