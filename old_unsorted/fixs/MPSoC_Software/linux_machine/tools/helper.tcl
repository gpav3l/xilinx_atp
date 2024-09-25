#
##########################################################################################################################################
#
# Helper file contains procs to support tcl scripts
#
# index: 
#    runDedScript  - source script - configures the arguments and launches the directedEditor
#    fixSlashes    - path          - replaces \\ with / when moving from Windows to Linux
#    unfixSlashes  - path          - replaces / with \\ when moving from Linux to Windows
#    use           - argument      - sets one of several global variables based on the argument <move to completer_helper>
#    strcmp        - a b           - returns a value > 0 if a > b, value < 0 if a < b, and 0 if equal. Comparison is case insensitive
#    strcontains   - a b           - returns value > 0 if b exists in a
#    strEndsWith   - a b           - returns value > 0 if a ends with b, 0 otherwise.  Comparison is case insensitive
#    strLastIndex  - a b           - returns the last position of b in a
#    strMatch      - a b           - returns 1 if a and b are case insensitive matches, 0 otherwise
#    markLastStep  - name          - remembers the name of the last step. used in conjunction with getLastStep <move to completer_helper>
#    getLastStep   -               - returns the name of the last step executed                                <move to completer_helper>
#    getLanguge    -               - returns the value of the language variabled. used in conjuction with "use" <move to completer_helper>
# urlFileGetText
# urlFileGetBinary
#    *** Log File procs:
#       logExist                   - returns true if log file exists (which means that it is currently capturing data)
#       logForceOpen <fname>       - opens a text file of fname to use as a log file. if a log file already exists, it is closed and this new file becomes the active log file
#       logOpen <fname>            - creates a text file of fname to use as a log file. if a log file already exists, a warning message is printed to the log file and no further changes to the data logging occur
#       openLogFile <fname>        - deprecated - same as logOpen
#       logClose <fname>           - flushes and closes the log file
#       closeLogFile <fname>       - deprecated - same as logClose
#       logWrite <msg>             - writes msg to log file and flushes
#       writeToLogFile <msg>       - deprecated - same as logWrite
#       logFlush                   - flushes the log file buffer to disk
#       flushLogFile               - deprecated - same as logFlush
#       boxedMsg <message>         - Makes a pretty box around message and sends to the log file and console
#       infoMsg <msg>              - dumps msg to log file and console with info flag and msg
#       warningMsg <msg>           - dumps msg to log file and console with warning flag and msg
#       errorMsg <msg>             - dumps msg to log file and console with error flag and msg
#       print <msg>                - dumps msg to log file and console with no formatting
#
#   *** File and directory management
#    workspacePath - builds proper path to workspace c:/training/$topic_name/workspace
#    labPath       - builds proper path to the lab    c:/training/$topic_name>/lab
#    demoPath      - builds proper path to the demo   c:/training/$topic_name/demo
#    getPathToJava - locates and returns the path to the newest version of the jre on the local machine (5/23/2016 - sc) (5/13/2016 - wk)
#    findFiles     - starting_dir namePattern - returns a list of files beginning at the starting_dir that match the namePattern
#    findDirectory - starting_dir namePattern - returns a list of directories beginning at the starting_dir that matches the namePattern
#    directoryExists - returns 1 if the specified directory exists, 0 otherwise
#    directoryWipe  - deletes directory and all content within that directory (rm -r)
#    stripLastHierarchy - removes last level of hierarchy in a path - this could be either file name or directory name
#    scanDir        - returns a list of all directories from the given path
#    hierarchyToList - converts a full path to a list of directories with the last entry being the file name
#
#    latestVersion - ip name (with old version #) - returns the same IP with the latest version number
#    
#
# History:
#    2018/06/05 - WK - fixed directoryWipe (now deletes recursively) - still doesn't work from the make all script
#    2018/04/10 - WK - copyIfNewer - added protection for missing source file
#    2018/04/03 - WK - added failed delete protection
#    2018/03/29 - WK - added new filesDelete and changed the old filesDelete to directoryWipe, findFiles now has a third argument for recursive searching
#    2018/03/27 - WK - added check to see if verbose was defined or not (to prevent "no such variable" errors), tested runJava proc, added logForceOpen
#    2017/11/28 - WK - added additional use capability - QEMU
#    08/28/2017 - WK - added getLatestXilinxVersion
#    08/28/2017 - WK - fixed activePeripheralList failure to initialize, cleaned up "use", added debug variable
#    07/31/2017 - WK - updated for 2017.1 including removal of SVN access (see developer_helper.tcl)
#    11/01/2016 - WK - added numerous procs to support 2016.3 and future releases
#    07/25/2016 - WK - added numerous procs to support 2016.1 release
#    04/15/2016 - WK - initial coding
#
###################################################################################################################################################
#

#!/usr/bin/tclsh

variable  ~/Tools/


puts "helper.tcl - 2018.1 - 2018/06/05"

# general use variables
variable language         undefined
variable platform         undefined
variable lastStep         notStarted
variable processor        undefined
variable activePeripheralList ""
variable debug            1
variable usingQEMU        0
variable tools            /training/tools
variable myLocation       [file normalize [info script]]
set suppressLogErrors     0

# used to indicate that the helper.tcl was loaded
variable helper loaded




# is verbose mode defined?
if {![info exists verbose]} {
   variable verbose 0;        # just define the verbose variable and keep it disabled
} 

#########################################################################
#
# procs for usability and debugging
#
#########################################################################
proc pause {{message "Hit Enter to continue ==> "}} {
    puts -nonewline $message
    flush stdout
    gets stdin
}

#########################################################################
#
# procs for building proper paths
#
#########################################################################
proc labPath {} {
   variable topicClusterName
   #variable labName
   #set path c:/training/$topicClusterName/labs/$labName
   set path ~/training/$topicClusterName/lab
   return $path
}
proc demoPath {} {
   variable topicClusterName
   set path ~/training/$topicClusterName/demo
   return $path
}
proc workspacePath {} {
   variable topicClusterName
   set path ~/training/$topicClusterName/workspace
   return $path
}
#########################################################################
#
# procs for managing drives
#
#    getDriveList - returns a list of available drives
#
# todo: http://twapi.magicsplat.com/v3.1/disk.html for get_volume_info 
#
#########################################################################
#package require twapi
#proc driveEject { target } {
# todo: make sure target is in the form: X: or X:/
#   eject_media $target
#}
#proc getDriveList {} {
#   return [file volumes];
#}
#########################################################################
#
# proc for identifying the newest version of Java (jre)
#
# assumes that java was installed into one of the two default directory
#
#########################################################################
proc getPathToJava {} {
   set maxVal ""
   set maxLength 0
   set javaDirs86 [glob -directory "c:/Program Files (x86)/Java" -type d -nocomplain *]
   set javaDirs   [glob -directory "c:/Program Files/Java" -type d -nocomplain *]
   set allJavaDirs {}
   append allJavaDirs $javaDirs " " $javaDirs86
   # allJavaDirs will contain a mix of jres and jdks. we only want the jres
   set cleanList {}
   foreach dir $allJavaDirs {
     set dirList [hierarchyToList $dir]
     set dirName [lindex $dirList [expr [llength $dirList] - 1]]
     # pull first 4 characters
     set type [substr $dirName 0 2]
     if {[strsame $type jre]} { lappend cleanList $dir}
   }
   set allJavaDirs $cleanList
   # puts "All Java Directories is now $allJavaDirs"

   # were any Java directories found? If not, we can't continue!
   if {[llength $allJavaDirs] == 0} {
      puts "No Java installation found! Cannot continue!";
     puts "Please install Java JRE in its default location!"
     puts "go to Java.com and download the free tool"
     return "";
   }
   
   # if some Java directories were found, then we can continue
   set javaPath ""
   foreach dir $allJavaDirs {
      # isolate just the directory name from the full path
      set firstIndex [string first jre1 $dir]
      set version    [string range $dir $firstIndex end]
      
      # break out the actual version number which will be in the form x.y_z*
      # find the last dot in the name and strip the string to that point
      set lastDot [string last . $version]
      incr lastDot -1
      set nextToLastDot [string last . $version $lastDot]
      incr nextToLastDot
      set length  [string length $version]
      set trimmedVersion [string range $version $nextToLastDot $length]
   
      # debug - the comparison should be on the version, the result should be the path
      # for now, just compare the entire directory
      set newLength [string length $trimmedVersion]
      set maxLength [string length $maxVal]
      if {$newLength > $maxLength} {
         set maxLength $newLength
         set maxVal $trimmedVersion
         set javaPath $dir
      } elseif {$newLength > $maxLength} {      
         if {[string compare -nocase $maxVal $trimmedVersion]} {
            if {$debug > 0} { puts "Setting new max to $trimmedVersion from directory $dir" }
            set maxVal $trimmedVersion
            set javaPath $dir
         }
      } else {
     }
   }
   # debug: javaPath not getting set 
   if {[string length $javaPath] == 0} {
      puts "was unable to find a path to Java!"
     return ""
   } else {
      return $javaPath/bin/java.exe
   }
}
#########################################################################
#
# proc for identifying the newest version of the Xilinx tools
#
# assumes that the tools was installed into the default directory
#
#########################################################################
proc getNewestXilinxVersion {} {
   set maxVal ""
   set maxLength 0
  
   
	set allVivadoVersionDirs [glob -directory "~/Tools/Vivado" -type d -nocomplain *]
   	set allSDKversionDirs [glob -directory "~/Tools/Vivado" -type d -nocomplain *]
	  
   set allXilinxVersionDirs {}
   append allXilinxVersionDirs $allVivadoVersionDirs " " $allSDKversionDirs

   # were any Java directories found? If not, we can't continue!
   if {[llength $allXilinxVersionDirs] == 0} {
      puts "No Xilinx installation found! Cannot continue!";
     puts "Please install the Xilinx tools to its default location!"
     puts "go to Xilinx.com > Support > Downloads and download the version you need"
     return "";
   }
   
   # if some directories were found, then we can continue
   set xilinxVersion 0
   foreach dir $allXilinxVersionDirs {
      # strip off the path information
     set lastHierarchySeparatorPos [expr [string last / $dir] + 1]
     set version [string range $dir $lastHierarchySeparatorPos [string length $dir]]
     
     # get rid of the dot which could screw up the comparisons
      set decimalPos [string last . $version]
      set trimmedVersion ""
      append trimmedVersion [string range $version 0 [expr $decimalPos - 1]] [string range $version [expr $decimalPos + 1] [string length $version]]
   
      # the comparison should be on the version, the result should be the newest (largest)
      if {$xilinxVersion < $trimmedVersion} {
         set xilinxVersion $trimmedVersion
      } 
   }
   # debug: javaPath not getting set 
   if {[string length $xilinxVersion] == 0} {
      puts "was unable to find a path to Xilinx!"
     return ""
   } else {
      # put the decimal point back in
     set retStr ""
     append retStr [string range $xilinxVersion 0 3] . [string range $xilinxVersion 4 5]
      return $retStr
   }
}
#########################################################################
#
# proc for finding files in the hierarchy <starting path, files to find, 1=recursive>
#
# returns a list of paths
#
#########################################################################
proc findFiles { basedir pattern recursive} {

   # Fix the directory name, this ensures the directory name is in the
   # native format for the platform and contains a final directory seperator
   set basedir [string trimright [file join [file normalize $basedir] { }]]
   set fileList {}

   # Look in the current directory for matching files, -type {f r}
   # means ony readable normal files are looked at, -nocomplain stops
   # an error being thrown if the returned list is empty
   catch {
      foreach fileName [glob -nocomplain -type {f r} -path $basedir $pattern] {
         lappend fileList $fileName
      }
   } err
   if {[string length $err] > 0} { puts "findFiles error value: $err" }

   # Now look for any sub direcories in the current directory
   if {$recursive} {
      catch {
         foreach dirName [glob -nocomplain -type {d  r} -path $basedir *] {
            # Recusively call the routine on the sub directory and append any
            # new files to the results
            set subDirList [findFiles $dirName $pattern 1]
            if { [llength $subDirList] > 0 } {
               foreach subDirFile $subDirList {
                  lappend fileList $subDirFile
               }
            }
         }
      } err
      if {[string length $err] > 0} { puts "subdirectory errors: $err" }
   }
   
   return $fileList
}
#########################################################################
#
# proc for finding a directory in the hierarchy
#
# returns true if the directory is found, false otherwise
#
#########################################################################
proc findDir { basedir pattern } {

    # Fix the directory name, this ensures the directory name is in the native format for the platform and contains a final directory seperator
    set basedir [string trimright [file join [file normalize $basedir] { }]]
    set fileList {}

    # Look in the current directory for matching files, -type {d} means ony directories are looked at, -nocomplain stops an error being thrown if the returned list is empty
   set targetName [glob -nocomplain -type {d} -path $basedir $pattern]
   if {[llength $targetName] > 0} { puts "found!"; return 1 }
   
    # Now look for any sub direcories in the current directory and recurse
    foreach dirName [glob -nocomplain -type {d  r} -path $basedir *] {
      set foundInThisBranch 0
        if {[catch {set findInThisBranch [findDir $dirName $pattern]} result]} {
         # puts "Error Management in the true portion of the if statement: $result"
      } 
      if { $foundInThisBranch == 1 } { return 1; }
    }
    return 0
}
#########################################################################
#
# proc for finding directory names in the hierarchy
#   - only one level of hierarchy depth
#
# returns list of occurance
#
#########################################################################
proc findInThisBranch { basedir pattern } {

    # Fix the directory name, this ensures the directory name is in the
    # native format for the platform and contains a final directory seperator
    set basedir [string trimright [file join [file normalize $basedir] { }]]
    set fileList {}

    # Look in the current directory for matching files, -type {f r}
    # means ony readable normal files are looked at, -nocomplain stops
    # an error being thrown if the returned list is empty
    foreach fileName [glob -nocomplain -type {d r} -path $basedir $pattern] {
        lappend fileList $fileName
    }

    # Now look for any sub direcories in the current directory
    #foreach dirName [glob -nocomplain -type {d  r} -path $basedir $pattern] {
        # Recusively call the routine on the sub directory and append any
        # new files to the results
        #set subDirList [findFiles $dirName $pattern]
        #if { [llength $subDirList] > 0 } {
        #    foreach subDirFile $subDirList {
        #        lappend fileList $subDirFile
        #    }
        #}
   #  lappend fileList $dirName
    #}
    return $fileList
}
#########################################################################
#
# proc for identifying if a file exists
#
# returns 1 if the file is found, 0 otherwise
#
#########################################################################
proc fileExists {target} { 
   set fexist [file exist $target]
   return $fexist 
}
proc isFile { target } {
   set fexist 0
   if {[fileExists $target]} {
      set fexist [file isfile $target]
   }
   return $fexist
}
#########################################################################
#
# proc for identifying if a directory exists
#
# returns 1 if the directory is found, 0 otherwise
#
#########################################################################
proc directoryExists {target} { return [file isdirectory $target] }
proc isDirectory {target} { return [file isdirectory $target] }
#########################################################################
#
# proc for removing directory and everything in it
#
#    recursive directory wipe - equivalent to rm -r
#
#########################################################################
proc directoryWipe { target } {
   if {[directoryExists $target]} {
      file delete -force -- $target
      file mkdir $target
   } else {
      warning "Directory $target does not exist therefore directoryWipe has nothing to work on"
   }
   # recreate the deleted directory
   file mkdir $target
}
# renamed as directoryWipe may wind up with a different behavior
proc directoryDelete { target } {
   if {[directoryExists $target]} {
      file delete -force $target
   } else {
      warning "Directory $target does not exist therefore directoryWipe has nothing to work on"
   }
}
#########################################################################
#
# proc directoryWipe (path to directory)
#
# erases all the files in the specified directory, but leaves the directory
#
#########################################################################
proc directoryWipe { target } {
   set fileList [getFiles $target]
   foreach thisFile $fileList {
      fileDelete $thisFile
   }
}

#########################################################################
#
# proc filesDelete (path)
#
# deletes all the files in the given list
#
#########################################################################
proc filesDelete { list } {
   foreach thisFile $list {
      fileDelete $thisFile
   }   
}
#########################################################################
#
# proc fileDelete (path)
#
#########################################################################
proc fileDelete { target } {
   if {[fileExists $target]} {
      catch {
         file delete -force $target
      } err
      if {[string length $err] > 0} {
         puts "could not delete $target - $err"
         if {[logExist]} {
            logWrite "could not delete $target - $err"
         }
      }
   } else {
      warning "File $target does not exist therefore fileDelete has nothing to work on"
   }
}
#########################################################################
#
# proc getFiles (path to directory) - returns a list of all files in this directory
#
#########################################################################
proc getFiles { target } {
    set basedir [string trimright [file join [file normalize $target] { }]]
    set fileList {}

    # Look in the current directory for matching files, -type {f r}
    # means ony readable normal files are looked at, -nocomplain stops
    # an error being thrown if the returned list is empty
    foreach fileName [glob -nocomplain -type {f r} -path $basedir *] {
        lappend fileList $fileName
    }
    
    return $fileList
 }
    
#########################################################################
#
# proc stripLastHierarchy (path) [limited protection, needs further testing]
#
#########################################################################
proc stripLastHierarchy {path} {
   set lastHierarchySeparator [string last / $path]
   set lastHierarchySeparator [expr $lastHierarchySeparator - 1]
   if {$lastHierarchySeparator > -1} {
      set returnString [string range $path 0 $lastHierarchySeparator]
   }
}
#########################################################################
#
# proc getLastHierarchy (path) [limited protection, needs further testing]
#
#########################################################################
proc getLastHierarchy {path} {
   set lastHierarchySeparator [string last / $path]
   set lastHierarchySeparator [expr $lastHierarchySeparator + 1]
   if {$lastHierarchySeparator > -1} {
      set returnString [string range $path $lastHierarchySeparator [string length $path]]
   }
}
#########################################################################
#
# scan directories inPath: returns list of directory names - not recursive
#
#########################################################################
proc scanDir { dir } {
   set contents [glob -type d -directory $dir *]
   set list {}
   foreach item $contents {
     lappend list $item
    # append out $item
    # append out " "
   }
   return $list
}
proc strIndex {s c from} {
   string first $c $s $from
}
#########################################################################
#
# hierarchyToList name
#
# returns list of directory names provided in "name". the file name will
# be the last element in the list
#
#########################################################################
proc hierarchyToList { name } {
   set hierarchyList {}
   
   # are any hierarchy separators found?
   set pos [expr [strIndex $name / 0] + 1]
   while {$pos > 0 && $pos < [string length $name]} {
      set nextPos [strIndex $name / [expr $pos + 1]]
     if {$nextPos == -1} { set nextPos [string length $name] }
     set thisHierarchyName [string range $name $pos [expr $nextPos - 1]]
     lappend hierarchyList $thisHierarchyName
     set pos [expr $nextPos + 1]
   }
   
   return $hierarchyList
}
#########################################################################
#
# containedIn (object,list) 
#
# returns 1 if object is contained in list, 0 otherwise
#
#########################################################################
proc containedIn {target list} {
   set result [lsearch -exact $list $target]
   if {[expr $result >= 0]} {
      set result 1
   } else {
      set result 0
   }
   return $result
}
#########################################################################
#
# commaSeparatedStringToList str
#
#########################################################################
proc commaSeparatedStringToList { str } {
   set list {}
   
   # are any hierarchy separators found?
   #set pos [expr [strIndex $str , 0] + 1]
   set pos [strIndex $str , 0]
   if {$pos != -1} { 
      set thisItem [string range $str 0 [expr $pos - 1]]
     lappend list $thisItem
     set pos [expr $pos + 1]
   } else {
      return $str
   }
   
   while {$pos < [string length $str]} {  
      set nextPos [strIndex $str , [expr $pos + 1]]
     if {$nextPos == -1} { set nextPos [string length $str] }
     set thisItem [string range $str $pos [expr $nextPos - 1]]
     lappend list $thisItem
     set pos [expr $nextPos + 1]
   }   
   return $list
}
#########################################################################
#
# spaceSeparatedStringToList str
#
#########################################################################
proc spaceSeparatedStringToList { str } {
   set list {}
   
   # are any hierarchy separators found?
   #set pos [expr [strIndex $str , 0] + 1]
   set space " "
   set pos [strIndex $str $space 0]
   if {$pos != -1} { 
      set thisItem [string range $str 0 [expr $pos - 1]]
     lappend list $thisItem
     set pos [expr $pos + 1]
   } else {
      return $str
   }
   
   while {$pos < [string length $str]} {  
      set nextPos [strIndex $str $space [expr $pos + 1]]
     if {$nextPos == -1} { set nextPos [string length $str] }
     set thisItem [string range $str $pos [expr $nextPos - 1]]
     lappend list $thisItem
     set pos [expr $nextPos + 1]
   }   
   return $list
}
#########################################################################
#
# proc for downloading a URL to the local directory
#
#########################################################################
package require http
proc urlFileGetText { url fName } {
   set fp [open $fName w]
   # no cleanup, so we lose some memory on every call
   append urlFile $url $fName
   puts $fp [ ::http::data [ ::http::geturl $urlFile ] ]
   close $fp
}
#########################################################################
# proc for downloading a binary 
#########################################################################
proc urlFileGetBinary { url fName } {
   set fp [open $fName w]
   # no cleanup, so we lose some memory on every call
   append urlFile $url $fName
   puts "Complete URL: $urlFile"
   set r [http::geturl $urlFile -binary 1]
   fconfigure $fp -translation binary
   puts -nonewline $fp [http::data $r]
   close $fp
   ::http::cleanup $r
}
#########################################################################
# proc for copying a file from src to dst if src is newer 
#########################################################################
proc copyIfNewer { src dst } {
   # check if source file exists
   if {![fileExist $src]} {
      if {[logExists]} {
         logWrite("attempted to copy $src to $dst, but source doesn't exist!");         
      } else {
         puts "attempted to copy $src to $dst, but source doesn't exist!"
      }
      return
   }
   # if dst doesn't exist then just copy
   if {![fileExist $dst]} {
      file copy -force -- $src $dst
   } else {
      # if dst does exist then get time/date for both src and dst
     set srcTimeDate [file mtime $src]
     set dstTimeDate [file mtime $dst]
      # if src newer than dst, copy
     if {$srcTimeDate > $dstTimeDate} {
        file copy -force -- $src $dst
     }
   }
}
#########################################################################
# proc for creating a directory if it doesn't yet exist
#########################################################################
proc createDir { dirName } {
   if {![directoryExists $dirName]} {
      file mkdir $dirName
   }
}
#########################################################################
# proc for launching the directed editor
#########################################################################
proc runDedScript {path_to_source path_to_script} {
   variable java
   variable tools
   set java [getPathToJava]
   set arguments ""
   append arguments $tools/directedEditor.jar "," $path_to_source "," $path_to_script
   regsub -all {' '} $arguments ',' arguments
   puts $arguments
   exec $java -jar $tools/directedEditor.jar $path_to_source $path_to_script
}
proc runDedScriptExtra {path_to_source path_to_script path_to_destination} {
   variable java
   variable tools
   set java [getPathToJava]
   set arguments ""
   append arguments $tools/directedEditor.jar "," $path_to_source "," $path_to_script
   regsub -all {' '} $arguments ',' arguments
   puts $arguments
   exec $java -jar $tools/directedEditor.jar $path_to_source $path_to_destination
}
# assumes toolName contains full path
# warning: this can be pretty picky with quotes in the argument list
proc runJava {toolName arguments} {
   variable verbose
   set verbose 1
   set java [getPathToJava]
   # iterate through the arguments list
   if {$verbose} {
      puts "listing passed arguments...$arguments"
      puts "now individually: "
   }
   set argumentString ""
   set argCount 0
   foreach argument $arguments {
      if {$verbose} { puts "$argCount: $argument" }
      append argumentString $argument
      incr argCount
      if {$argCount < [llength $arguments]} { 
         append argumentString ","
      }
   }
   if {$verbose} {
      puts "argument string is $argumentString"
      puts "java location: $java"
      puts "tool name with path: $toolName"   
   }
   puts "getting ready to run the tool"
   # catch any errors to avoid breaking the calling routine
   if {[catch {exec $java -jar $toolName $argumentString} resultText]} {
      puts "failed execution: $::errorInfo"
   } else {
      puts "successful execution - application returned $resultText"
   }
}
#########################################################################
# proc for launching the choicesGUI
#########################################################################
proc runChoicesGUI {path_to_source argList} {
   variable java
   set java [getPathToJava]
   exec $java -jar $path_to_source $argList
}
#########################################################################
# proc for fixing slashes from Windows to Linux
#########################################################################
proc fixSlashes {path} {
   
   # replace below with the following and verify
   regsub -all {\\} $path / path
   
   # set len [string length $path]
   # for {set i 0} {$i < $len} {incr i} {
      # set c [string index $path $i]
      # if {$c == "\\"} {
         # set path [string replace $path $i $i "/"]
      # }
   # }
   return $path
}

#########################################################################
# proc for fixing slashes from Linux to Windows
#########################################################################
proc unfixSlashes {path} {
   
   # replace below with the following and verify
   regsub -all / $path {\\} path
   
   # set len [string length $path]
   # for {set i 0} {$i < $len} {incr i} {
      # set c [string index $path $i]
      # if {$c == "/"} {
         # set path [string replace $path $i $i "\\"]
      # }
   # }
   return $path
}

#########################################################################
# proc for doing wide range of configurable items
#########################################################################
proc use { thing } {
   variable processor
   variable hdfName
   variable language
   variable platform   
   variable userIO   
   variable MPSoCactivePeripheralList
   variable APSoCactivePeripheralList
   variable activePeripheralList
   variable usingQEMU
   variable debug
   
   # if the variable is not yet in use, initialize it
   if {[info exists processor] == 0} { set processor undefined }   
   if {[info exists hdfName] == 0}   { set hdfName   undefined }
   if {[info exists language] == 0}  { set language  undefined }   
   if {[info exists platform] == 0}  { set platform  undefined }  
   if {[info exists userIO] == 0}    { set userIO    base }      
   if {[info exists usingQEMU] == 0} { set usingQEMU 0}
   
   # what kind of platform is being used? Determine the hdf name and type of processor
   if { [string compare -nocase $thing "ZC702"] == 0 } {       
      set platform  ZC702
      if { [string compare -nocase $processor "MicroBlaze"] != 0} {
         if {$debug} { puts "platform: ZC702; using A9" }
         set processor ps7_cortexa9_0 
        
         if {[info exists APSoCactivePeripheralList]} {
           set activePeripheralList $APSoCactivePeripheralList
         } else {
           puts "Variable APSoCactivePeripheralList must be defined and filled with user defined peripherals."
           puts "In order to keep this script running, this variable will be defined, but not filled with any peripherals"
           set activePeripheralList {}   
         } 
      } else {
         # processor is a MicroBlaze
         if {$debug} { puts "platform: ZC702; using uB" } 
      }    
   } elseif { [string compare -nocase $thing "Zed"] == 0 } {
      set platform  Zed
      if { [string compare -nocase $processor "MicroBlaze"] != 0} {
        if {$debug} { puts "platform: Zed; using A9" } 
         set processor ps7_cortexa9_0 
      
        # assign peripheral list
       if {[info exists APSoCactivePeripheralList]} {
          set activePeripheralList $APSoCactivePeripheralList
        } else {
          puts "Variable APSoCactivePeripheralList must be defined and filled with user defined peripherals."
         puts "In order to keep this script running, this variable will be defined, but not filled with any peripherals"
         set activePeripheralList {}
       }  
     } else {
        # processor is a microblaze
       if {$debug} { puts "platform: Zed; using uB" } 
     }
   } elseif { [string compare -nocase $thing "KC705"] == 0 } {
       set processor microblaze_0
       set platform  KC705
       puts "!!! Deprecated board! (KC705) !!!"
   } elseif {[strsame $thing "ZCU102"]} {
      set platform ZCU102
      if {[info exists MPSoCactivePeripheralList]} {
         set activePeripheralList $MPSoCactivePeripheralList
     }
   } elseif {[string compare -nocase $thing "RFSoC"] == 0} {
      set processor zynq_ultra_ps_e_0 
      set platform RFSoC_board;
      puts "targing a non-existant RFSoC board by using only the part"
      if {[info exists MPSoCactivePeripheralList]} {
         puts "setting the peripheral list for this device"
         set activePeripheralList $MPSoCactivePeripheralList
      }      
   } elseif { [string compare -nocase $thing "base"] == 0 } {
      set userIO base
   } elseif { [string compare -nocase $thing "FMC-CE"] == 0 } {
      set userIO FMC-CE
   } elseif {[string compare -nocase $thing "VHDL"] == 0} {
      set language VHDL
   } elseif {[string compare -nocase $thing "Verilog"] == 0} {
      set language Verilog
   } elseif {[string compare -nocase $thing "A9"] == 0} {
      set processor ps7_cortexa9_0
   } elseif {[string compare -nocase $thing "ps7_cortexa9_0"] == 0} {
      set processor ps7_cortexa9_0
   } elseif {[string compare -nocase $thing "APU"] == 0} {
      set processor A53
   } elseif {[string compare -nocase $thing "A53"] == 0} {
      set processor A53
   } elseif {[string compare -nocase $thing "RPU"] == 0} {
      set processor R5
   } elseif {[string compare -nocase $thing "R5"] == 0} {
      set processor R5
   } elseif {[string compare -nocase $thing "PMU"] == 0} {
      set processor MicroBlaze
   } elseif {[string compare -nocase $thing "MicroBlaze"] == 0} {
      set processor MicroBlaze
   } elseif {[string compare -nocase $thing "microblaze_0"] == 0} {
      set processor MicroBlaze
   } elseif {[string compare -nocase $thing "uB"] == 0} {
      set processor MicroBlaze
   } elseif {[string compare -nocase $thing "QEMU"] == 0} {
      set usingQEMU 1
   } else {
      puts "Unknown use item! $thing"
      return
   }
   # puts "PS peripheral list is set to $activePeripheralList"
}

#########################################################################
#
# inList item list_of_things - returns true or false if item is in the list
#
# returns 0 if item is not in list, 1 if it is
#
#########################################################################
proc inList {item thisList} {
   set result [lsearch $thisList $item];
   if {$result != -1} {return 1} 
   return 0;
}
#########################################################################
#
# strReplaceChar (s x c) - returns string s where character x is replaced by character c
#
#########################################################################
proc strReplace {s target replacement} {
   set retStr [regsub -all $target $s $replacement]
   return $retStr
}
#########################################################################
#
# strlen (a) - returns number of characters in a
#
#########################################################################
proc strlen {a} {
   return [string length $a]
}

#########################################################################
#
# strcmp (a,b) - performs case insensitive comparison
#
# returns -1 if a<b, 0 if a=b, 1 if a>b
#
#########################################################################
proc strcmp {a b} {
   return [string compare -nocase $a $b]
}

#########################################################################
#
# strsame (a,b) - performs case insensitive comparison
#
# returns 1 if they are the same (case not withstanding), otherwise 0
#
#########################################################################
proc strsame {a b} {
   set comparisonValue [string compare -nocase $a $b]
   if {$comparisonValue == 0} { return 1 } else { return 0 }
}
#########################################################################
#
# proc for locating the last occurrance of the given symbol
#
#########################################################################
proc lastIndexOf { s c } {
   string last $c $s
   puts "Obsolete - use strLastIndex instead of lastIndexOf"
}
#########################################################################
#
# strLastIndex (a,b) - returns the position corresponding to the last
#                      occurrance of b in a
#
#########################################################################
proc strLastIndex {a b} {
   set pos [string last $b $a]
   return $pos
}
# the following appears to return the end of the string starting at the position where b was found
   # if {$pos > -1} {   
      # set pos [incr pos]
      # set str [string range $a $pos [string length $a]]
     # return $str
   # }
   # return "?"
# }
#########################################################################
#
# strMatch (a,b) - returns 1 if and b are case insensitive matches, 0 otherwise
#
#########################################################################
proc strMatch {a b} {
   set comparisonValue [string compare -nocase $a $b]
   if {$comparisonValue == 0} { return 1 } else { return 0 }
}
#########################################################################
#
# strContains (a,b) - returns 1 if b is in a
#
#########################################################################
proc strContains {a b} {
   set pos [string first $b $a]
   if {$pos > -1} { return 1; }
   return 0;
}
#########################################################################
#
# strPosition (a,b) - returns position of b if in a, -1 otherwise
#
#########################################################################
proc strPosition {a b} {
   set pos [string first $b $a]
   if {$pos > -1} { return $pos; }
   return -1;
}
#########################################################################
#
# substr (x,start,end) - returns string from start to end
#
#########################################################################
proc substr {x a b} {
   set retVal "Error in substring $x $a $b";
   if {[strlen $x] >= $a} { 
      if {[strlen $x] >= $b} {
        set retVal [string range $x $a $b]
     }
   }
   return $retVal;
}
#########################################################################
#
# strEndsWith (a,b) - does string a end with string b?
#
# returns 0 if no, 1 if yes
#
#########################################################################
proc strEndsWith {a b} {
   set A [string toupper $a]
   set B [string toupper $b]
   set endsWith [string last $B $A]
   set endPosShouldBe [expr [string length $A] - [string length $B]]
   if { $endsWith == $endPosShouldBe } {
      return 1;
   } else {
      return 0;
   }
}
#########################################################################
#
# invertLogic (x) - returns the inverse logic value
#
# returns "yes"  if "no" is passed and vica-versa
#         "1"    if "0"  is passed and vica-versa
#         "true" if "false" is passed and vica-versa
#
#########################################################################
proc invertLogic {x} {
   if {[strsame $x "yes"]} { 
      return "no"
   } elseif {[strsame $x "no"]} { 
      return "yes"
   } elseif {$x != 0} { 
      return 1
   } elseif {$x == 0} {
      return 1
   } elseif {[strsame $x "true"]} { 
      return "false"
   } elseif {[strsame $x "false"]} { 
      return "true"
   } else {
      return "?"
   }
}
#########################################################################
#
# logicValue (x) - returns 1 or 0 based on x
#
# returns 1 if x is 1, true, or yes; 0 otherwise
#
#########################################################################
proc logicValue {x} {
   if {[strsame $x "yes"]} { 
      return 1
   } elseif {[strsame $x "true"]} { 
      return 1
   } elseif {[strsame $x "1"]} { 
      return 1
   }
   return 0
}
#########################################################################
# proc for marking the step that was just completed
#########################################################################
proc markLastStep { lastStepName } {
   variable lastStep
   set lastStep $lastStepName
}
proc getLastStep {} { variable lastStep; return $lastStep }
proc getLanguage {} { variable language; return $language }

#########################################################################
#
# print - prints to both STDOUT and log file (if opened)
#
#########################################################################
proc print { msg } {
   puts $msg
   logWrite $msg
}

#########################################################################
#
# log file management procs and variables
#
#########################################################################
variable log
variable logPath

# use these procs moving foward, the other procs are present for backward compatability
proc logExists {} { logExist; }
proc logExist { } {
   variable log
   variable logPath
   # is the log file already open?
   if {[info exist log] == 1} {
      return 1;
   }
   return 0;
}
proc logForceOpen { logFileName } {
   variable log
   variable logPath
   # is the log file already open?
   if {[info exist log] == 1} {
     errorMsg "Log file already open when attempting to open new log file: $logFileName. Closing existing log file and opening new one"
     logClose
   }
   
   # does the logFileName already end in .log?
   if {[strEndsWith $logFileName .log] != 0} {
      set logPath $logFileName
   } else {
      set logPath ""
      append logPath $logFileName .log
   }
   set log [open $logPath w]

   # start the log
   set today [clock format [clock seconds] -format %Y-%m-%d]
   set now   [clock format [clock seconds] -format %H:%M:%S]
   print "$logFileName started at $now on $today"
   logWrite "\n\n"
}
proc logOpen { logFileName } {
   variable log
   variable logPath
   # is the log file already open?
   if {[info exist log] == 1} {
     errorMsg "Log file already open when attempting to open new log file: $logFileName. Will continue with existing log file."
     print "Log file already open when attempting to open new log file: $logFileName. Will continue with existing log file."
     set today [clock format [clock seconds] -format %Y-%m-%d]
     set now   [clock format [clock seconds] -format %H:%M:%S]
     print "attempt to open $logFileName at $now on $today failed. Continuing to use $logPath"    
     logWrite "\n\n"     
   } else {
     # open the file normally
     logForceOpen $logFileName
   }
}
proc openLogFile { logFileName } {
   logOpen $logFileName
   logWrite "deprecated use of openLogFile found!"
}
proc logWrite {s} {
   variable log
   variable suppressLogErrors
   # get the string into the output buffer
   if {[logIsOpen]} { 
      puts $log $s
      # ensure that this buffer gets pushed to the file in case of a crash
      flush $log
   } else {
      if { $suppressLogErrors == 0} { puts "log file wasn't open!!!"   }
   }
}
proc writeLogFile {s} {
   logWrite $s
   logWrite "deprecated use of writeLogFile found!"
}
proc logFlush {} {
   variable log
   flush $log
}
proc flushLogFile {} {
   logWrite "deprecated use of flushLogFile found!"
   logFlush
}
proc logClose {} {
   variable log
   variable logPath
   
   # if there is a log to close...
   if { [info exists log] } {
   
      # show the time/date stamp for the closing
      set today [clock format [clock seconds] -format %Y-%m-%d]
      set now   [clock format [clock seconds] -format %H:%M:%S]     
     
      # dump the message to the log file and console
      print "$logPath closed at $now on $today"
      logWrite "\n"
   
      # empty the buffer and close the file
      flush $log
      close $log
     
      # remove the log so that it is no longer defined and that info exists will return 0 showing log is closed
      unset log
   } else {
      puts "*Error* No log file open"
   }
}
proc closeLogFile {} {
   logClose
   logWrite "deprecated use of closeLogFile found!"
}
proc logIsOpen {} {
   variable log
   return [info exists log]
}
proc infoMsg { msg } {
   if {[logIsOpen] == 1} {
      logWrite "----- Info: $msg"
     puts     "----- Info: $msg"
   }
}
proc warningMsg { msg } {
   if {[logIsOpen] == 1} {
      logWrite "===== Warning: $msg"
     puts     "===== Warning: $msg"
   }
}
proc errorMsg { msg } {
   if {[logIsOpen] == 1} {
      logWrite "!!!!! Error: $msg"
     puts     "!!!!! Error: $msg"
   }
}
#########################################################################
#
# user file management procs: fileOpen, fileWrite, fileRead, fileClose
#
#########################################################################
variable fileHandle
variable fileName
variable fileStatus
set fileStatus CLOSED

# mode is w for writing, a for appending
proc fileOpen {fName mode} {
   variable fileName
   variable fileHandle
   variable fileStatus
   # is the file already open?
   if {[strMatch $fileStatus CLOSED]} {
      # ready to open
     set fileName $fName
     set fileHandle [open $fName $mode]     
     if {[strMatch $mode w]} {
        set fileStatus OPEN_FOR_WRITING
     } elseif {[strMatch $mode a]} {
        set fileStatus OPEN_FOR_APPENDING
     } elseif {[strMatch $mode r]} {
        set fileStatus OPEN_FOR_READING
     }
   }
}
proc fileWrite {msg} {
   variable fileName;
   variable fileHandle;
   variable fileStatus;
   if {[strMatch $fileStatus OPEN_FOR_WRITING] || [strMatch $fileStatus OPEN_FOR_APPENDING]} {      
      puts $fileHandle $msg
      # ensure that this buffer gets pushed to the file in case of a crash
      flush $fileHandle
   } else {
      puts "Cannot write to $fileName because it's status is currently listed as: $fileStatus"
   }
}
proc fileRead {} {
   variable fileName
   variable fileHandle
   variable fileStatus
   
   set rtnStr READ_FAILURE
   
   if {[strMatch $fileStatus OPEN_FOR_READING]} {
      if {[atEOF]} {
        puts "Can't read from $fileName because we are at the end of file and there is no more data"
     } else {
         set readString [gets $fileHandle]
       return $readString
     }      
   } else {
      puts "Can't read from $fileName because it is currently $fileStatus"
   }
   return ""
}
proc atEOF {} {
   variable fileHandle
   variable fileStatus
   
   if {![strMatch $fileStatus CLOSED]} {
      set status [eof $fileHandle]
      return $status
   } else {
      puts "Can't ready from $fileName because it is currently $fileStatus"
   }
}
proc fileClose {} {
   variable fileName
   variable fileHandle
   variable fileStatus
   
   if {![strMatch $fileStatus CLOSED]} {
      if {[strMatch $fileStatus OPEN_FOR_APPENDING] || [strMatch $fileStatus OPEN_FOR_WRITING]} {
         flush $fileHandle
     }
      close $fileHandle
     set fileStatus CLOSED
   } else {
      puts "Can't close $fileName because it is already closed!"
   }
}
#
# *** graphic reminder that the section of the script has completed
#     step number is argument
#
proc doneWithStep { n } { 
   print "**************************";
   print "*  Done Running Step $n   *";
   print "**************************";
}
#
#########################################################################
#
# boxedMsg (m) - dumps m to the log file and terminal
#
# puts m in pretty box
# centered - 11/04/2016 WK
# future - add wrap
#
#########################################################################
#
proc boxedMsg { x } {
   set minWidth 50

   # how wide is the message?
   # future - adjust for cr/lfs in the msg (wrap)
   set xWidth [string length $x]
   # 5 for the leading 2 *s, 2 for the trailing *s, 1 for the each space btwn * and msg
   set totalWidth [expr $xWidth + 2 + 2 + 2]
   
   # ensure that there is a minimum width
   if {$totalWidth < $minWidth} { set totalWidth $minWidth }
   
   # build the top 2 lines (blank line and all asterisks)
   print ""
   set allAsterisks [repeat * $totalWidth]
   print "\t$allAsterisks"

   # 3rd line is asterisks at front and back of line
   set blankedLine ""
   append blankedLine "**" [repeatChar " " [expr $totalWidth - 4]] "**"
   print "\t$blankedLine"

   # 4th line contains the message
   # if smaller than minWidth, then center in the fields
   # first half is totalWidth/2 - "** " - half of the msg width
   set firstHalfBuffer  [expr $totalWidth / 2 - 3 - $xWidth / 2]
   # second half is what ever is left over to account for rounding: including "**" and "**" and whole word
   set secondHalfBuffer [expr $totalWidth - $firstHalfBuffer - $xWidth - 6]    
   set msgLine ""
   append msgLine "\t** " [repeatChar " " $firstHalfBuffer] $x [repeatChar " " $secondHalfBuffer] " **"
   print "$msgLine"

   # finish up with what we started with
   print "\t$blankedLine"
   print "\t$allAsterisks"
   print ""
}

proc repeatChar { c n } {
   set s ""
   for {set i 0} {$i < $n} {incr i} {
      append s $c
   }
   return $s
}

#########################################################################
#
# proc for identifying the newest version of IP
#
# pass in IP name and this function will return the newest version of that IP
#
#########################################################################
proc latestVersion { IPname } {
   # find the package type
   set packageTypes {iclg }
   set lastPos [strLastIndex $IPname :]; # strip off everything beyond the third colon (as this contains the version info)
   set IPnameNoVer [string range $IPname 0 $lastPos]
   
   set listOfAllIP [get_ipdefs]
   foreach pieceOfIP $listOfAllIP {
      set lastPos [strLastIndex $pieceOfIP :]; # strip off everything beyond the third colon (as this contains the version info)
      set pieceOfIPnoVer [string range $pieceOfIP 0 $lastPos]
      if {[string compare $pieceOfIPnoVer $IPnameNoVer] == 0} { 
         return $pieceOfIP
      }
   }
}

#########################################################################
#
# proc for identifying the closest part number
#
# pass in a partial part name and this function will return the first match of this part 
# matches to core part minus speed grade, temp grade, es, etc.
# this is useful when a specific part is not required, rather only a member of a family
# and size
# todo: add wildcards
#
#########################################################################
proc closestPart { partNumber } {
   # before we go through the lengthly process of searching, is this part already in the list?
   set partList [get_parts]
   set exactResult [lsearch $partList $partNumber]
   if {$exactResult > -1} {
      return $partNumber;
   }

   # list of known packages
   set packages {clg iclg sclg ifbg isbg sbg fbg fbv ifbv iffg iffv fbg ffg ffv cl rf rb ffvb ffvc ffvd sfva sfvc}

   # strip off the package id
   foreach thisPkg $packages {
      # set pkgPos [strLastIndex $partNumber $packages]; # look for this package in the part
      # if pkgPos > -1 means that it's found
      set pkgPos [strLastIndex $partNumber $thisPkg]
      if {$pkgPos > -1} {
       set partialPart [substr $partNumber 0 $pkgPos]
         append partialPart "*"
         # now find the first partial match...
         set fullPartPosition [lsearch $partList $partialPart]
         set fullPart [lindex $partList $fullPartPosition]
         return $fullPart
      }
   }
   return "???"
}

#########################################################################
#
# proc for copying src to dst
#
# catches any error and prevents Tcl from aborting execution of script
#
#########################################################################
proc safeCopy { src dst } {
   # attempt to copy and catch status of copy
   if { [catch {file copy -force -- $src $dst} fid] } {
       puts stderr "Could not copy $src to $dst\n$fid"
       writeLogFile "Could not copy $src to $dst\n$fid"
       flushLogFile
      return 0
   }
   return 1
}
#########################################################################
#
# proc for moving src to dst
#
# catches any error and prevents Tcl from aborting execution of script
#
#########################################################################
proc safeMove { src dst } {
   # attempt to copy and catch status of copy
   if { [catch {file copy -force -- $src $dst} fid] } {
      puts stderr "Could not copy $src to $dst\n$fid"
      writeLogFile "Could not copy $src to $dst\n$fid"
      flushLogFile
      return 0
   }
   # attempt to delete and catch status of deletion
   if { [catch {file delete -force -- $src} fid] } {
      puts stderr "Could not delete $src\n$fid"
      writeLogFile "Could not delete $src\n$fid"
      flushLogFile
      return 0
   }   
   return 1
}

#########################################################################
#
# returns the name of the proc this proc is called from
#
#########################################################################
proc procName {} {
   set trace [strace]
   set thisLevel [info level]
   # since trace is still sitting on the stack we have to go up two instead of one
   set upTwoLevels [expr $thisLevel - 2]
   set thisLevelName [lindex $trace $upTwoLevels]
   return $thisLevelName
}

proc dumpStack {} {
    set trace [strace]
    puts "Trace:"
    foreach t $trace {
        puts "* ${t}"
    }
}

proc strace {} {
    set ret {}
    set r [catch {expr [info level] - 1} l]
    if {$r} { return {""} }
    while {$l > -1} {
        incr l -1
        lappend ret [info level $l]
    }
    return $ret
}

proc getScriptLocation {} {
   variable myLocation
   return [file dirname $myLocation]
}
#
# set paths to important places
#
variable tclLoc
variable custEdServer
# Removed by LR set java [getPathToJava]

##########################################################################
#
# proc isDigit character
#
# returns 0 if the character is not a digit, 1 otherwise
#
##########################################################################
proc isDigit {c} {
   if {[string length $c] == 0} { return 0; }
   set c [string range $c 0 1 ]
   if {$c>=0&$c<=9} { return 1 }
   return 0
}
##########################################################################
#
# proc extractIntegerFromString
#
# extracts all digits from within a string - 123ABC456 => 123456
#
##########################################################################
proc extractIntegerFromString {s} {
   set integer ""
   for {set i 0} {$i < 10} {incr i} {
      set thisChar [string range $s $i [expr $i + 0]]
      if { [isDigit $thisChar] } { append integer $thisChar; }
   }
   return $integer
}
###########################################################################
#
# proc toHex decVal
#
###########################################################################
proc toHex { decVal } {
   return [format 0x%x $decVal]
}
###########################################################################
#
# proc msSleep decVal
# - requires Tcl 8.4
###########################################################################
proc msSleep { ms } {
     after $ms
 }
 ##########################################################################
 #
 # randName(length)
 # creates a random string of length
 #
 ###########################################################################
 proc randName {len} {
    set retStr ""
    for {set i 0} {$i<$len} {incr i} {
      set value [expr int(rand()*127)]
       set char [format %c $value]   
      if {(($value >= 48) && ($value <=  57) && ($i > 0)) || 
          (($value >= 65) && ($value <=  90)) ||
           (($value >= 97) && ($value <= 122)) } {
          # this is a legal symbol and should be appended to the return string        
        append retStr $char
      } else {
        # this is an illegal symbol and should be skipped
        incr i -1;               
      } 
   }
   return $retStr;
 }
 ##########################################################################
 #
 # catonate (X Y)
 # appends Y to X
 #
 ###########################################################################
 proc catonate {x y} { 
    set z ""
   append z $x $y
   return $z
 } 
 ##########################################################################
 #
 # zip srcDir destFile
 #
 ###########################################################################
 proc zipIt {srcDirName destFileName} {
    # point to the 7zip tool which may be called if there is unzipping to be done
    set zipToolPath [findFiles {c:/Program Files} 7z.exe 1];  # assumes default location
   if {[llength $zipToolPath]} {
      set zipToolPath [lindex $zipToolPath 0]
      
      # confirm that the source is valid
      if {[isDirectory $srcDirName]} {
         exec $zipToolPath a -tzip $destFileName $srcDirName;           # zip it!
      } else {
         puts "zipIt - source directory not found: $srcDirName"
      }
   } else {
      puts "zipIt - could not locate 7 zip utility in the default installation site"
   }
}

# Note: does not display if run in quiet mode
puts "Helper is $helper"
