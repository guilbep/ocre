class neuron =
object(self)

  val mutable value = 0.
  val mutable error = 0.
  val mutable nextweights = Array.make 1 1.
  val mutable predweight = Array.make 1 1.

end