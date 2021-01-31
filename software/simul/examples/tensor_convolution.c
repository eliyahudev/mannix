#include "../include/cnn_inc.h"


int main(int argc, char const *argv[]) {
    int N,M;
    int label;

    if (argc >1)
        N = atoi(argv[1]);
    else
        N = 6;
    if (argc >2)
        M = atoi(argv[2]);
    else
        M = N;


    //memory allocated
    int data[500000];
    Matrix alloc_matrix[500];
    Tensor tens[100];

    //declare allocotors 
    Allocator al[1];
    MatAllocator mat_al[1];
    TensorAllocator tens_alloc[1];

    // declare 4D tensor 
    Tensor4D tens_4d[1];
    Tensor4D tens_4d_test[1];

    // allocate memory
    createAllocator(al, data, 40000);
    createMatrixAllocator(mat_al, alloc_matrix, 500);
    createTensorAllocator( tens_alloc, tens, 100);


    // set the layer of the cnn 
    int layer = 2;

    // import matricies
    char* path = {"../../python/csv_dumps/scaled_int2/"};
    create4DTensor(tens_4d, 5, 5, 6, 12, al, mat_al, tens_alloc);
    create4DTensor(tens_4d_test, 5, 5, 1, 6, al, mat_al, tens_alloc);

    // set tensor
    set4DTensor(tens_4d, path, layer);
    set4DTensor(tens_4d_test, path, 1);

    printD4Tensor(tens_4d_test);
    printD4Tensor(tens_4d);

    return 0;
}

