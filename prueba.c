#include <stdio.h>

int a ;
int b ;

main () 
{
	a = 10 ;
	
	while (a > 0) {
		printf ("%d", a) ;
		if (a % 2 == 0) { 
			puts (" es par ") ;
		} else {
			puts (" es impar ") ;
		}
		a = a - 1 ;
	} 
}

//@ (main)

