class data :
  int ->
  int ->
  object
    val mutable inputs : int array
    val mutable nbinputs : int
    val mutable nboutputs : int
    val mutable outputs : int array
      method print_input : unit -> unit


      method get_input : int -> int
      method get_inputs : unit -> int array
      method get_nbinputs : int
      method get_nboutputs : unit -> int
      method get_output : int -> int
      method get_outputs : unit -> int array
      method init_bool_op : int -> int -> int -> unit
      method set_input : int -> int -> unit
      method set_inputs : int array -> unit
      method set_nbinputs : int -> unit
      method set_nboutputs : int -> unit
      method set_output : int -> int -> unit
      method set_outputs : int array -> unit
  end

class tab_xor :
object
  val mutable tab : data array
  method get_tab : unit -> data array
  method set_tab : data array -> unit
  method init_tab : unit -> unit
  method get_pos_tab : int -> data
end

class data_alpha:
object
  val mutable char : int
  val mutable tab_input : int array
  method get_char : unit -> int
  method get_tab : unit -> int array
  method get_tabpos : int -> int
  method init_tab : string -> unit
  method set_char : int -> unit
  method set_tab : int array -> unit
  method set_tabpos : int -> int -> unit
  method zero_or_one : int -> int
end

class alphabet :
object
  val mutable tab : data_alpha array
  val mutable tab_string : string array
  method get_string_tab : int -> string
  method get_tab : unit -> data_alpha array
  method get_tabpos : int -> data_alpha
  method init_tab_alpha : unit -> unit
  method set_tab : data_alpha array -> unit
  method set_tabpos : int -> data_alpha -> unit
end
