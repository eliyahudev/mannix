#include "../include/cnn_inc.h"



int main(int argc, char const *argv[]) {
    int N,M,D;
    int label;

    if (argc >1)
        N = atoi(argv[1]);
    else
        N = 28;
    if (argc >2)
        M = atoi(argv[2]);
    else
        M = N;
    if(argc > 3)
        D = atoi(argv[3]);
    else
        D = 1;

    //memory allocated
    int data[500000];
    Matrix alloc_matrix[100];
    
    //declare allocotors 
    Allocator al[1];
    MatAllocator mat_al[1];

    // allocate memory
    createAllocator(al, data, 40000);
    createMatrixAllocator(mat_al, alloc_matrix, 100);

    // declare and get access to matrix and tensors via pointer
    Tensor tens[1];

    // create matrix from exel file     
    FILE *imageFilePointer = fopen("../source/data_set_256_fasion_emnist.csv", "r");

    // set tensor size to 3 5x5 matricies 
    createTensor(5, 5, 3, tens, al, mat_al);
    setMatrixToTensor(tens, imageFilePointer, &label, 1);
        
    printf("\n matrix before maxpooling: \n");
    printTensor(tens);

    tensorMaxPool(tens,2,2,2);

    printf("\n result matrix after maxpooling: \n");
    printTensor(tens);

    // sanity check - make sure the data is stored sequntianly
    for (size_t i = 0; i < 12; i++) {
        printf("%d ,", tens->matrix[0].data[i]);
    }
    
    fclose(imageFilePointer);

    return 0;
}