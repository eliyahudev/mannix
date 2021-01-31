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
    
    //declare allocotors 
    Allocator al[1];

    // allocate memory
    createAllocator(al, data, 40000);

    // declare and get access to matrix via pointer
    Matrix image[1];
    Matrix filter[1];
    Matrix bias[1];
    Matrix result_matrix[1];

    // get image, filter, bias files     
    FILE *imageFilePointer = fopen("../source/data_set_256_fasion_emnist.csv", "r"); 
    FILE *filterFilePointer = fopen("../../python/csv_dumps/scaled_int2/conv1_w_0_0.csv", "r");
    FILE *biasFilePointer = fopen("../../python/csv_dumps/scaled_int2/conv1_b.csv", "r");

    printf("\n matrix before maxpooling: \n");
    // create matrix from exel file     
    creatMatrix(N ,M , image, al);
    creatMatrix(5 ,5 , filter, al);
    creatMatrix(5 ,1 , bias, al);

    getMatrix(image,imageFilePointer, &label,0, 0);
    getMatrix(filter,filterFilePointer, &label,0, 1);
    getMatrix(bias,biasFilePointer, &label,0, 1);
    
    matrixConvolution(image, filter, bias->data[0], result_matrix, al);
    
    printf("\n result matrix after convolution: \n");
    printMatrix(result_matrix);

    fclose(imageFilePointer);
    fclose(filterFilePointer);
    fclose(biasFilePointer);
    return 0;
}

