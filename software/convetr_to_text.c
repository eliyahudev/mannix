
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
 
int main()
{
    int val;
    char strn1[3] ;
    strn1[0] = '1' ;
    strn1[1] = '2' ;
    strn1[3] = '\0' ;

    
 
    val = atoi(strn1);
    printf("String value = %s\n", strn1);
    printf("Integer value = %d\n", val);
 
    char strn2[] = "GeeksforGeeks";
    val = atoi(strn2);
    printf("String value = %s\n", strn2);
    printf("Integer value = %d\n", val);
 
    return (0);
}
