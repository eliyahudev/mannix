#include "include/cnn_inc.h"



int main(int argc, char const *argv[]) {
    int N,M;
    if (argc >1)
        N = atoi(argv[1]);
    else
        N = 28;
    if (argc >2)
        M = atoi(argv[2]);
    else
        M = N;
    
// #ifdef TEST
// #include test.h
// #endif

    //create memory allocator;
    int data[10000];
    Allocator al[1];
    createAllocator(al, data, 10000);

    // create and get access to matrix via pointer
    Matrix m[1];
    Matrix m2[1];
    Matrix m3[1];
    Matrix m4[1];

    creatMatrix(N ,M , m, al);
    creatMatrix(4 ,4 , m2, al);
    // create matrix from exel file 
    int label;
    
    FILE *filePointer = fopen("source/data_set_256_fasion_emnist.csv", "r");
    // FILE *filePointer2 = fopen("source/zeros.csv", "r");
    
    getMatrix(m, filePointer, &label, -1);
    getMatrix(m2, filePointer, &label, -1);

    cnnConvolutionLayer(m, m2, m3, al);
    
    fclose(filePointer);

    return 0;
}

