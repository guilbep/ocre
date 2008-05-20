class perceptron input output nbhlayers nbn =
object(self)
  val mutable nblayers = nbhlayers + 2
  val mutable layers = Array.make (nbhlayers + 2) 
    (new Layer.layer nbn)
  val mutable learning_rate = 0.1
  val mutable patterns = new Data.data input output
  val mutable quad_error = 69.

  method init() = 
    layers.(0) <- new Layer.layer input;
    layers.(nbhlayers + 1) <- new Layer.layer output

  method learn() = print_int 42
(*

7 etapes :

   1. Placer le groupe de données (pattern) en entré
   2. Trouver les valeurs des cellules cachées
   3. Trouver les valeurs des cellules de sortie
   4. Trouver l'erreur dans la couche de sortie
   5. Utiliser l'algorithme de rétro-propagation pour ajuster les poids des connections menant aux cellules de sortie
   6. Utiliser une formule pour trouver les erreurs sur la couche cachée
   7. Ajuster les poids menant aux cellules de la couche cachée

*)

(*1*)

(*2*)

(*3*)

(*4*)

(*5*)

(*6*)

(*7*)


end

