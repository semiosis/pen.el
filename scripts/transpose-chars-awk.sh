#!/bin/bash

# https://unix.stackexchange.com/questions/383164/how-to-transpose-a-text-file-on-character-basis

delimiter=""
sep=""

transpose() { : # comment sed for newer awks.
              # Do this to separate characters in quite old awk
              # very old wak does not allow that the FS could be Null.
              #sed -e 's/./ &/g' "$file" |
              awk ' 
                   { for(i=1;i<=NF;i++){a[NR,i]=$i};{(NF>m)?m=NF:0} }
                   END { for(j=1; j<=m; j++)
                         { for(i=1; i<=NR; i++)
                           { b=((a[i,j]=="")?" ":a[i,j])
                             printf("%s%s",(i==1)?"":sep,b)
                           }
                           printf("\n")
                         }
                       }
                   ' FS="$delimiter" sep="$sep" cc="$countcols"
             }

transpose