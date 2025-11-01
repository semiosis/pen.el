#!/usr/bin/env crun

#include <regex.h>
#include <stdio.h>
#include <stdlib.h>

/* needed https://stackoverflow.com/q/3025050 */

regex_t regex;
char msgbuf[100];

/* 7d236681b ~ master semiosis/master 19:53 scripts/c-scripts δ » regex-test.c
   7342,32432
   7342,32432
   
   Match
   37428,4354
   37428,4354 */

int main(int argc, char const *argv[])
{
    int reti = regcomp(&regex, "^(-)?([0-9]+)((,|.)([0-9]+))?\n$", REG_EXTENDED);

    while(1){
        fgets( msgbuf, 100, stdin );
        if (reti) {
            fprintf(stderr, "Could not compile regex\n");
            exit(1);
        }

        /* Execute regular expression */
        printf("%s\n", msgbuf);
        reti = regexec(&regex, msgbuf, 0, NULL, 0);
        if (!reti) {
            puts("Match");
        }
        else if (reti == REG_NOMATCH) {
            puts("No match");
        }
        else {
            regerror(reti, &regex, msgbuf, sizeof(msgbuf));
            fprintf(stderr, "Regex match failed: %s\n", msgbuf);
            exit(1);
        }

        /* Free memory allocated to the pattern buffer by regcomp() */
        regfree(&regex);
    }

}
