BEGIN {
   l_filter="toolchain,servers"
   if (l_filter != "") {
      split(l_filter, f_arr, ",")
      for (f in f_arr) {
         allowed_layers[f_arr[f]] = 1
         allowed_layers[f_arr[f] "s"] = 1
      }
   }
}
{
   layer = $1
   if (l_filter != "" && !(layer in allowed_layers) && layer != "cli") {
      next
   }
   print "Allowing:", $2
}
