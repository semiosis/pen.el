#!/usr/bin/php
<?php
// https://stackoverflow.com/q/5966902
//
system("stty -icanon");                                  // Enable shell input
system("stty -echo");                                    // Disable characters printing
echo "\e[?1003h\e[?1015h\e[?1006h";                      // Mouse trap all, urxvt, SGR1006

function shutdown(){                                     // Cleaning before quiting
    echo "\e[?1000l";                                    // Disable mouse trap
    system("stty echo");                                 // Enable back characters printing
    exit;                                                // Cleaned, quit
}
register_shutdown_function("shutdown");                  // Handle regular END of script

declare(ticks = 1);                                      // Allow POSIX signal handling
pcntl_signal(SIGINT,"shutdown");                         // Catch SIGINT (CTRL + C)

$KEY = "";
while ($KEY = fread(STDIN,16)) {
  // Record xterm mouse:
  // file_put_contents('/tmp/mouse.txt', $KEY . "\n", FILE_APPEND);

  $e = explode(";",explode("<",$KEY)[1]);
  if ($e[0] === "0" && substr($e[2],-1) === "M"){
     echo "BUTTON DOWN, LINE ".substr($e[2],0,-1)." COLUMN ".$e[1]."\n";
  }
  if ($e[0] === "0" && substr($e[2],-1) === "m"){
     echo "BUTTON UP, LINE ".substr($e[2],0,-1)." COLUMN ".$e[1]."\n";
  }
  if ($e[0] === "64"){
     echo "WHEEL SCROLL UP, LINE ".substr($e[2],0,-1)." COLUMN ".$e[1]."\n";
  }
  if ($e[0] === "65"){
     echo "WHEEL SCROLL DOWN, LINE ".substr($e[2],0,-1)." COLUMN ".$e[1]."\n";
  }
  if ($e[0] === "1" && substr($e[2],-1) === "M"){
     echo "WHEEL BUTTON DOWN, LINE ".substr($e[2],0,-1)." COLUMN ".$e[1]."\n";
  }
  if ($e[0] === "1" && substr($e[2],-1) === "m"){
     echo "WHEEL BUTTON UP, LINE ".substr($e[2],0,-1)." COLUMN ".$e[1]."\n";
  }
  if ($e[0] === "35"){
     echo "MOUSE MOVE, LINE ".substr($e[2],0,-1)." COLUMN ".$e[1]."\n";
  }
}