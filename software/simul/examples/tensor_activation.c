#include "../include/cnn_inc.h"


int main(int argc, char const *argv[]) {

// like-dynamic memory allocation for the program 
#include "../include/tensor_allocation_setup.h"

    // declare 4D tensors
    Tensor4D image[1];
    Tensor4D filter[2];
    Tensor4D result_4D_tensor[1];

    // declare matrix bias [for each matrix there is one bias value, for example for image->matrix[0] we add the same value bias->data[0] to all cells]
    Matrix conv_bias[2];
    Matrix fc_bias[2];
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
    // allocate memory for image, filter and bias
    create4DTensor(&image[0], 28, 28, 3, 1, al, mat_al, tens_alloc);
    create4DTensor(&filter[0], 5, 5, 1, 6, al, mat_al, tens_alloc);
    create4DTensor(&filter[1], 5, 5, 6, 12, al, mat_al, tens_alloc);
    creatMatrix(6,1,&conv_bias[0],al);
    creatMatrix(12,1,&conv_bias[1],al);
    creatMatrix(120,1,&fc_bias[0],al);
    creatMatrix(64,1,&fc_bias[1],al);
    
    // set values from csv table
    setImage(&image[0], imageFilePointer);
    setFilter(&filter[0], path, 1);
    setFilter(&filter[1], path, 2);
    setBias(&conv_bias[1], path, "conv", 2, "b");
    setBias(&conv_bias[0], path, "conv", 1, "b");
    setBias(&fc_bias[0], path, "fc", 1, "b");
    setBias(&fc_bias[1], path, "fc", 2, "b");

//  convolution layer 
    tensor4DConvolution(image, filter, conv_bias, result_4D_tensor, al, mat_al, tens_alloc);
    printf("tensor's value after convolution and before activation\n");
    print4DTensor(result_4D_tensor);
    tensor4DActivation(result_4D_tensor);
    printf("tensor's after activation\n");
    print4DTensor(result_4D_tensor);
    /*======================== TODO ADD ACTIVATION LAYER =================================*/
    
    fclose(imageFilePointer);

#ifdef VS_MANNIX
    free(data);  // we may use float for the first test infirence
    free(alloc_matrix);
    free(tens);
#endif

    return 0;
}

