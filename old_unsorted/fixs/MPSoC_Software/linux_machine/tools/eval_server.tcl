proc Eval_Server {port {interp {}} {openCmd EvalOpenProc}} {
  socket -server [list EvalAccept $interp $openCmd] $port
}

proc EvalAccept { interp openCmd newsock addr port} {
  global eval
  set eval(cmdbuf,$newsock) {}
  fileevent $newsock readable [list EvalRead $newsock $interp]
  if [catch {
    interp eval $interp $openCmd $newsock $addr $port
    # puts "Accept $newsock from $addr : $port"
  }] {
    close $newsock
  }
}

proc EvalOpenProc {sock addr port} {
  #authenticate here
}

proc EvalRead {sock interp} {
  global eval errorInfo errorCode
  if [eof $sock] {
    close $sock
  } else {
    gets $sock line
    #debug - reports line received: puts "got line : $line"
    append eval(cmdbuf,$sock) $line
    if {[string length $eval(cmdbuf,$sock)] && [info complete $eval(cmdbuf,$sock)]} {
      # Special case- client sends "exit".  Deal with it gracefully
      if {[string compare -nocase $eval(cmdbuf,$sock) "exit"] == 0 } {
        puts $sock 1 
        puts $sock "0 {Server exited} {} {}"
        flush $sock
        # puts "SOCKET $sock CMD: $eval(cmdbuf,$sock) RESULT: 0\n"
        exit
      }
      set code [catch {
        if {[string length $interp] == 0} {
          uplevel #0 $eval(cmdbuf,$sock)
        } else {
          interp eval $interp $eval(cmdbuf,$sock)
        }
      } result]
      
      #set reply [list $code $result $errorInfo $errorCode]\n
      set reply [list $result]\n
      #puts "errorInfo : $errorInfo"
      #puts "errorCode : $errorCode"
      # use regsub to count newlines
      set lines [regsub -all \n $reply {} junk]
      puts "$sock CMD: ($lines) $eval(cmdbuf,$sock) RESULT: $result\n"
      # the reply is a line count followed by a tcl list that occupies that occupies number of lines
      #puts $sock $lines
      puts -nonewline $sock $reply
      flush $sock
      set eval(cmdbuf,$sock) {}
    }
  }
}
proc Eval_Open {server port} {
  global eval
  set sock [socket $server $port]
  # save this info for later reporting
  set eval(server,$sock) $server:$port
  return $sock
}

proc Eval_Remote {sock args} {
  global eval
  #preserve the concat semantics of eval
  if {[llength $args] > 1} {
    set cmd [concat $args]
  } else {
    set cmd [lindex $args 0]
  }
  puts $sock $cmd
  flush $sock
  #read return line count and the result
  gets $sock lines
  set result {}
  while {$lines > 0} {
    gets $sock x
    append result $x\n
    incr lines -1
  }
  set code [lindex $result 0]
  #puts "return code : $code"
  set x [lindex $result 1]
  # cleanup the end of the stack
  regsub "\[^\n]+$" [lindex $result 2] \
    "*Remote Server $eval(server,$sock)*" stack
  #puts "stack: $stack"
  set ec [lindex $result 3]
  #puts "ec: $ec"
  return -code $code -errorinfo $stack -errorcode $ec $x
}

proc Eval_Close {sock} {
  close $sock
}    

Eval_Server 2540
vwait forever
