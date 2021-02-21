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
    int* data = (int*)malloc(sizeof(int)* MANNIX_DATA_SIZE);  // we may use float for the first test infirence
    Matrix* alloc_matrix = (Matrix*)malloc(sizeof(int)* MANNIX_MAT_SIZE);
    Tensor* tens = (Tensor*)malloc(sizeof(Tensor)* MANNIX_TEN_SIZE);
#else
    int data[MANNIX_DATA_SIZE];  // we may use float for the first test infirence
    Matrix alloc_matrix[MANNIX_MAT_SIZE];
    Tensor tens[MANNIX_TEN_SIZE];
#endif

    //declare allocotors 
    Allocator al[1];
    MatAllocator mat_al[1];
    TensorAllocator tens_alloc[1];

    // allocate memory
    createAllocator(al, data, MANNIX_DATA_SIZE);
    createMatrixAllocator(mat_al, alloc_matrix, MANNIX_MAT_SIZE);
    createTensorAllocator( tens_alloc, tens, MANNIX_TEN_SIZE);

    // declare 4D tensors
#ifdef VS_MANNIX
    Tensor4D* image = (Tensor4D*)malloc(sizeof(Tensor4D)*1);
    Tensor4D* filter = (Tensor4D*)malloc(sizeof(Tensor4D)*2);
    Tensor4D* result_4D_tensor = (Tensor4D*)malloc(sizeof(Tensor4D) * 1);

#else
    Tensor4D image[1];
    Tensor4D filter[2];
    Tensor4D result_4D_tensor[1];
#endif
    // declare matrix bias [for each matrix there is one bias value, for example for image->matrix[0] we add the same value bias->data[0] to all cells]
    Matrix bias[2];
    
    

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
    
    // set values
    setImage(&image[0], imageFilePointer);
    setFilter(&filter[0], path, 1);
    setFilter(&filter[1], path, 2);
    setBias(&bias[1], path, 2);
    setBias(&bias[0], path, 1);

    printf("image\n");
    print4DTensor(&image[0]);
    printf("filter\n");
    print4DTensor(&filter[0]);
    printf("bias\n");
    printMatrix(bias);
// ======================= convolution ==============================================
    printf("\n3D convolution:\n");
    tensor4DConvolution(image, filter, bias, result_4D_tensor, al, mat_al, tens_alloc);
    print4DTensor(result_4D_tensor);
// ==================================================================================

    fclose(imageFilePointer);

#ifdef VS_MANNIX
    free(data);  // we may use float for the first test infirence
    free(alloc_matrix);
    free(tens);
    free(image);
    free(filter);
    free(result_4D_tensor);
#endif

    return 0;
}

