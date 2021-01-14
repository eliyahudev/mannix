
#include <stdio.h>
#include <stdlib.h>

void* getData(FILE* filePointer, int data_to_read, int* label, int* x)
{
    //1
    char ch;
    char strn1[4] ;
    //int x[100];
//    int* x  = (int*) malloc(data_to_read * sizeof(int));
    int n = 0, k = 0;
    size_t i=0;

    //3
    if (filePointer == NULL)
    {
        printf("File is not available \n");
        exit(-1);
    }
    else
    {
        //4
        while (k < data_to_read && (ch = fgetc(filePointer)) != EOF)
        {
            if (ch >= '0' && ch <='9') {
                strn1[n++] = ch;
            }

            if (ch == ',' || ch == '\t' || ch == ' ' || ch == '\n') {
                strn1[n] = '\0';
                n=0;
                if(k==0) {
                    label[k++] = atoi(strn1);
                }
                else {
                    x[k++ - 1] = atoi(strn1); 
                }
            }
        }
    }
        
    //5

    return x;
}


