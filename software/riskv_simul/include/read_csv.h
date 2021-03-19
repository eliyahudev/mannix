#ifndef READ_CSV
#define READ_CSV

#define LENGTH 32



void getData_int32(FILE* filePointer, int data_to_read, int* label, int* x, int op) {
    char ch ;
    //char exp_sign;
    char strn1[LENGTH];
    //char* expon;
    int n = 0, k = 0;
    size_t i=0;

    if (filePointer == NULL)
    {
        printf("File is not available \n");
        printf("please checkout man_def.h -> \"environment setups\" \n");
        exit(-1);
    }
    
    while (k < data_to_read && (ch = fgetc(filePointer)) != EOF) {
        while (ch == ' ' && (ch = fgetc(filePointer)) != EOF);  //  TODO - CHANGE INT FORM LIKE FLOAT FORM $$$$$$$$$$ VERY IMPORTANT!!!!! $$$$$$$$$$$$
        // negative sign only at the start of a number
        if (ch == '-')
            if (0 == n) strn1[n++] = ch;
            else exit(-1);

        if (ch >= '0' && ch <='9')  strn1[n++] = ch;
        if (ch == '.' ) strn1[n++] = ch;
        if (ch == ',' || ch == '\n') {
                            
            strn1[n] = '\0';
            n=0;
            if(k==0 && op == 0) label[k++] = atoi(strn1); 

            else if(k == 0 && op != 0) {
                label[k] = -1;
                x[k++] = (int)atoi(strn1); 
            }
            else if(op == 0) x[k++ - 1] = (int)atoi(strn1);  
            else  x[k++] = (int)atoi(strn1); 
        }
    }     
} // getData


void getData_int8(FILE* filePointer, int data_to_read, int* label, signed char* x, int op) {
    char ch ;
    //char exp_sign;
    char strn1[LENGTH];
    //char* expon;
    int n = 0, k = 0;
    size_t i=0;

    if (filePointer == NULL)
    {
        printf("File is not available \n");
        printf("please checkout man_def.h -> \"environment setups\" \n");
        exit(-1);
    }
    
    while (k < data_to_read && (ch = fgetc(filePointer)) != EOF) {
        while (ch == ' ' && (ch = fgetc(filePointer)) != EOF);  //  TODO - CHANGE INT FORM LIKE FLOAT FORM $$$$$$$$$$ VERY IMPORTANT!!!!! $$$$$$$$$$$$
        // negative sign only at the start of a number
        if (ch == '-')
            if (0 == n) strn1[n++] = ch;
            else exit(-1);

        if (ch >= '0' && ch <='9')  strn1[n++] = ch;
        if (ch == '.' ) strn1[n++] = ch;
        if (ch == ',' || ch == '\n') {
                            
            strn1[n] = '\0';
            n=0;
            if(k==0 && op == 0) label[k++] = atoi(strn1); 

            else if(k == 0 && op != 0) {
                label[k] = -1;
                x[k++] = (signed char)atoi(strn1); 
            }
            else if(op == 0) x[k++ - 1] = (signed char)atoi(strn1);  
            else  x[k++] = (signed char)atoi(strn1); 
        }
    }     
} // getData


void getData_uint8(FILE* filePointer, int data_to_read, int* label, unsigned char* x, int op) {
    char ch ;
    //char exp_sign;
    char strn1[LENGTH];
    //char* expon;
    int n = 0, k = 0;
    size_t i=0;

    if (filePointer == NULL)
    {
        printf("File is not available \n");
        printf("please checkout man_def.h -> \"environment setups\" \n");
        exit(-1);
    }
    
    while (k < data_to_read && (ch = fgetc(filePointer)) != EOF) {
        while (ch == ' ' && (ch = fgetc(filePointer)) != EOF);  //  TODO - CHANGE INT FORM LIKE FLOAT FORM $$$$$$$$$$ VERY IMPORTANT!!!!! $$$$$$$$$$$$
        // negative sign only at the start of a number
        if (ch == '-')
            if (0 == n) strn1[n++] = ch;
            else exit(-1);

        if (ch >= '0' && ch <='9')  strn1[n++] = ch;
        if (ch == '.' ) strn1[n++] = ch;
        if (ch == ',' || ch == '\n') {
                            
            strn1[n] = '\0';
            n=0;
            if(k==0 && op == 0) label[k++] = (unsigned char)atoi(strn1); 

            else if(k == 0 && op != 0) {
                label[k] = -1;
                x[k++] = (unsigned char)atoi(strn1); 
            }
            else if(op == 0) x[k++ - 1] = (unsigned char)atoi(strn1);  
            else  x[k++] = (unsigned char)atoi(strn1); 
        }
    }     
} // getData




FILE* createFilter(char* file_path, int layer, int filter_num, int filter_depth) {
    char path[64];
    strcpy(path, file_path);
    char cast_int[3]; // todo - add "warning this function hendle up to 3 digit layer"  
    char str[64] = "conv";

    itoa(layer, cast_int, 10);
    strcat(str, cast_int);
    strcat(str, "_w_");
    itoa(filter_num, cast_int, 10);
    strcat(str,  cast_int);
    itoa(filter_depth, cast_int, 10);
    strcat(str, "_");
    strcat(str, cast_int);
    strcat(str, ".csv");
    strcat(path,str);
    strcat(path,"\0");

    FILE *FilePointer = fopen(path,"r");
    return FilePointer;
    
}

FILE* createFdFc(char* file_path, char* conv_fc, int layer, char* w_b) {
    char path[60];
    strcpy(path, file_path);
    char cast_int[3]; // todo - add "warning this function hendle up to 3 digit layer"  
    char str[32] = "";

    strcat(str, conv_fc);
    itoa(layer, cast_int, 10);
    strcat(str, cast_int);
    strcat(str, "_");
    strcat(str, w_b);
    strcat(str, ".csv");
    strcat(path,str);
    strcat(path,"\0");

    FILE *FilePointer = fopen(path,"r");
    return FilePointer;
    
}

#endif
