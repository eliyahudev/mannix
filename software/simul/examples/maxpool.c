#include "../include/cnn_inc.h"


int main(int argc, char const *argv[]) {
    int N,M;
    int label;

    if (argc >1)
        N = atoi(argv[1]);
    else
        N = 28;
    if (argc >2)
        M = atoi(argv[2]);
    else
        M = N;

    //memory allocated
    int data[500000];
    
    //declare allocotors 
    Allocator al[1];

    // allocate memory
    createAllocator(al, data, 40000);

    // declare and get access to matrix via pointer
    Matrix image[1];

    // create matrix from exel file     
    FILE *imageFilePointer = fopen("../source/data_set_256_fasion_emnist.csv", "r");
        
    printf("\n matrix before maxpooling: \n");
    creatMatrix(N ,M , image, al);
    getMatrix(image,imageFilePointer, &label,0, 0);
    
    matrixMaxPool(image, 2,2,2);
    
    printf("\n result matrix after maxpooling: \n");
    printMatrix(image);

    fclose(imageFilePointer);

    return 0;
}

