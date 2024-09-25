# xsct_example.tcl
proc gen3apps {} {
   foreach newAppName {first_app second_app third_app} {
      puts "Building $newAppName..."
      sdk createapp -name $newAppName -hwproject ZC702_hw_platform -proc ps7_cortexa9_0 -os standalone\
         -lang C -app {Hello World} -bsp test_bsp
   }
}
