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
    int data[500000];
    Matrix alloc_matrix[100];

    Allocator al[1];
    MatAllocator mat_al[1];
    
    createAllocator(al, data, 40000);
    createMatrixAllocator(mat_al, alloc_matrix, 100);
    
    Tensor tens[1];

    // create and get access to matrix via pointer
    Matrix m[1];
    Matrix m2[1];
    Matrix m3[1];
    Matrix m4[1];

    creatMatrix(N ,M , m, al);
    creatMatrix(4 ,4 , m2, al);
    // create matrix from exel file 
    int label;
    
    // todo - chage filepointer for a more generic use (while loop) 
    FILE *filePointer = fopen("source/data_set_256_fasion_emnist.csv", "r");
    //FILE *filterFilePointer = fopen("../../python/csv_dumps/scaled_int2/conv1_b", "r");

    createTensor(5, 5, 3, tens, al, mat_al);
    setMatrixToTensor(tens, filePointer, &label);

    printTensor(tens);

 //   tensorFlatten(tens) ;
 //   printTensor(tens);

    getMatrix(m, filePointer, &label, -1, 0);
    getMatrix(m2, filePointer, &label, -1, 0);

    // maxPool(tens->matrix[0], m2

    fclose(filePointer);

    return 0;
}

