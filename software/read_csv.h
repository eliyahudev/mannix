#include <stdio.h>
#include <stdlib.h>

int* getData(char* path, int data_to_read)
{
    //1
    FILE *filePointer;
    char ch;
    char strn1[4] ;
    //int x[100];
    int* x  = (int*) malloc(data_to_read * sizeof(int));
    int n = 0, k = 0;
    size_t i=0;
    //2
    filePointer = fopen(path, "r");

    //3
    if (filePointer == NULL)
    {
        printf("File is not available \n");
    }
    else
    {
        //4
        while ((ch = fgetc(filePointer)) != EOF && k < data_to_read)
        {
            if (ch >= '0' && ch <='9') {
                strn1[n++] = ch;
                printf("%c", ch);
            }
            if (ch == ',' || ch == '\t' || ch == ' ') {
                strn1[n] = '\0';
                n=0;
                x[k++] = atoi(strn1); 
                printf("%c", ' ');
            }
            if (ch == '\n') {
                strn1[n] = '\0';
                n=0;
                x[k++] = atoi(strn1); 
                printf("%c", '\n');
            }
        }
    }
    
    for (i = 0; i < k; i++)
    {
        printf("%d\n", x[i]);
    }
    
    //5
    fclose(filePointer);

    return x;
}


