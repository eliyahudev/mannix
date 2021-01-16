#ifndef READ_CSV
#define READ_CSV

#define LENGTH 5

void* getData(FILE* filePointer, int data_to_read, int* label, int* x)
{
    char ch;
    char strn1[LENGTH] ;
    int n = 0, k = 0;
    size_t i=0;


    if (filePointer == NULL)
    {
        printf("File is not available \n");
        exit(-1);
    }
    else
    {
        while (k < data_to_read && (ch = fgetc(filePointer)) != EOF)
        {
            if (ch == '-')
                if (0 == n)
                    strn1[n++] = ch;
                else
                    exit(-1);

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

#endif
