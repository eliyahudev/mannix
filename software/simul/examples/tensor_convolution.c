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
#ifdef VS_MANNIX
    int* data = (int*)malloc(sizeof(int)*500000);  // we may use float for the first test infirence
    Matrix* alloc_matrix = (Matrix*)malloc(sizeof(int)*500);
    Tensor* tens = (Tensor*)malloc(sizeof(Tensor)*100);
#else
    int data[500000];  // we may use float for the first test infirence
    Matrix alloc_matrix[500];
    Tensor tens[100];
#endif
    //declare allocotors 
    Allocator al[1];
    MatAllocator mat_al[1];
    TensorAllocator tens_alloc[1];

    // allocate memory
    createAllocator(al, data, 40000);
    createMatrixAllocator(mat_al, alloc_matrix, 500);
    createTensorAllocator( tens_alloc, tens, 100);

    // declare 4D tensors
#ifdef VS_MANNIX
    Tensor4D* image = (Tensor4D*)malloc(sizeof(Tensor4D)*1);
    Tensor4D* filter = (Tensor4D*)malloc(sizeof(Tensor4D)*2);
#else
    Tensor4D image[1];
    Tensor4D filter[2];
#endif
    // declare matrix bias [for each matrix there is one bias value, for example for image->matrix[0] we add the same value bias->data[0] to all cells]
    Matrix bias[2];
    Matrix result_matrix[1];
    

    // import matricies
#ifdef VS_MANNIX
    char* path = {"../../../python/csv_dumps/scaled_int2/"};
    FILE *imageFilePointer = fopen("../../source/data_set_256_fasion_emnist.csv", "r"); 
#else 
    char* path = { "../../python/csv_dumps/scaled_int2/" };
    FILE* imageFilePointer = fopen("../source/data_set_256_fasion_emnist.csv", "r");
#endif
    // set the layer of the cnn 
    int layer = 1;

    create4DTensor(&image[0], 28, 28, 3, 1, al, mat_al, tens_alloc);
    create4DTensor(&filter[0], 5, 5, 1, 6, al, mat_al, tens_alloc);
    create4DTensor(&filter[1], 5, 5, 6, 12, al, mat_al, tens_alloc);
    creatMatrix(6,1,&bias[0],al);
    creatMatrix(12,1,&bias[1],al);
    // set tensor
    for (size_t i = 0; i < image->depth; i++) {
        addScalarMatrix(&image->tensor->matrix[i], 3);
    }    
    // setImage(&image[0], imageFilePointer);
    setFilter(&filter[0], path, 1);
    setFilter(&filter[1], path, 2);
    setBias(&bias[1], path, 2);
    setBias(&bias[0], path, 1);


    print4DTensor(&image[0]);
    print4DTensor(&filter[0]);
    // printf("\n\n");
    // printMatrix(&bias[1]);

    // printf("3D convolution:\n");
    tensorConvolution(&image[0].tensor[0], &filter[0].tensor[0].matrix[0], bias[0].data[0], result_matrix, al, mat_al);
    printMatrix(result_matrix);
    // printf("\nrows: %d, cols: %d\n",result_matrix->rows, result_matrix->cols);

    fclose(imageFilePointer);

#ifdef VS_MANNIX
    free(data);  // we may use float for the first test infirence
    free(alloc_matrix);
    free(tens);
    free(image);
    free(filter);
#endif

    return 0;
}

