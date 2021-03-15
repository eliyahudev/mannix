#include "../include/cnn_inc.h"


int main(int argc, char const *argv[]) {

// like-dynamic memory allocation for the program 
#include "../include/tensor_allocation_setup.h"

    // declare 4D tensors
    Tensor4D image[1];
    Tensor4D filter[2];
    Tensor4D result_4D_tensor[2];

    // declare matrix bias [for each matrix there is one bias value, for example for image->matrix[0] we add the same value bias->data[0] to all cells]
    Matrix conv_bias[2];
    
    Matrix fc_weight[3];
    Matrix fc_bias[3];
    Matrix result_matrix[3];
    
    // import matricies
#ifdef VS_MANNIX
    #ifdef DISABLE_SCALE
        char* path = {"../../../python/csv_dumps/float_orig/"};
    #else
        char* path = { "../../../python/csv_dumps/scaled_int/" };
    #endif
//    FILE* imageFilePointer = fopen("../../../../../test_and_delete/mannix_test/inference/img_csv_dumps/img_9558.csv", "r");
     FILE *imageFilePointer = fopen("../../test_src/data_set_256_fasion_emnist.csv", "r"); 
#else 
    #ifdef DISABLE_SCALE
        char* path = { "../../python/csv_dumps/float_orig/" };
    #else
        char* path = { "../../python/csv_dumps/scaled_int/" };
    #endif
    FILE* imageFilePointer = fopen("../test_src/data_set_256_fasion_emnist.csv", "r");
#endif
    // allocate memory for image, filter and bias
    create4DTensor(&image[0], 28, 28, 1, 1, al, mat_al, tens_alloc);
    create4DTensor(&filter[0], 5, 5, 1, 6, al, mat_al, tens_alloc);
    create4DTensor(&filter[1], 5, 5, 6, 12, al, mat_al, tens_alloc);
    creatMatrix(6, 1, &conv_bias[0], al);
    creatMatrix(12, 1, &conv_bias[1], al);
    creatMatrix(120, 192, &fc_weight[0], al);
    creatMatrix(64, 120, &fc_weight[1], al);
    creatMatrix(10, 64, &fc_weight[2], al);
    creatMatrix(120,1, &fc_bias[0], al);
    creatMatrix(64,1, &fc_bias[1], al);
    creatMatrix(10,1, &fc_bias[2], al);
    
    // set values from csv table
    setFilter(&filter[0], path, 1);
    setFilter(&filter[1], path, 2);
    setBias(&conv_bias[1], path, "conv", 2, "b");
    setBias(&conv_bias[0], path, "conv", 1, "b");
    setBias(&fc_bias[0], path, "fc", 1, "b");
    setBias(&fc_bias[1], path, "fc", 2, "b");
    setBias(&fc_bias[2], path, "fc", 3, "b");
    setWeight(&fc_weight[0], path, "fc", 1, "w");
    setWeight(&fc_weight[1], path, "fc", 2, "w");
    setWeight(&fc_weight[2], path, "fc", 3, "w");

    // print4DTensor(&filter[1]);
    // printMatrix(conv_bias);

#ifdef DISABLE_SCALE
    //mullScalarMatrix(image->tensor->matrix, 1.0/256.0);    
    // print4DTensor(image);
#endif
    
    float success_count = 0;
    float fail_count = 0;

    DATA_TYPE* reset_mannix_data = al->data;
    int reset_mannix_data_index = al->index ;
    Matrix* reset_mannix_matrix = mat_al->matrix ;
    int reset_mannix_matrix_index = mat_al->index ;
    Tensor* reset_mannix_tensor = tens_alloc->tensor ;
    int reset_mannix_tensor_index = tens_alloc->index ;

#ifdef TEST
    for (int a = 0; a < 100; a++) {
#else
    while (!feof(imageFilePointer)) {
#endif
        al->data = reset_mannix_data ;
        al->index = reset_mannix_data_index ;
        mat_al->matrix = reset_mannix_matrix ;
        mat_al->index = reset_mannix_matrix_index ;
        tens_alloc->tensor = reset_mannix_tensor ;
        tens_alloc->index = reset_mannix_tensor_index ;

        int real_label = setImage(&image[0], imageFilePointer);

    //  convolution layer 
        tensor4DConvolution(image, filter, conv_bias, result_4D_tensor, al, mat_al, tens_alloc);
        // printf("tensor after convolution layer 1 and before activation\n");
        // print4DTensor(result_4D_tensor);
        tensor4DActivation(result_4D_tensor);
        // printf("tensor after activation\n");
        // print4DTensor(result_4D_tensor);
        tensor4DMaxPool(result_4D_tensor, 2, 2, 2);
        // printf("tensor after maxpooling\n");
        // print4DTensor(result_4D_tensor);

        tensor4DConvolution(&result_4D_tensor[0], &filter[1], &conv_bias[1], &result_4D_tensor[1], al, mat_al, tens_alloc);
        // printf("tensor after convolution layer 2 and before activation\n");
        // print4DTensor(&result_4D_tensor[1]);
        tensor4DActivation(&result_4D_tensor[1]);
        // printf("tensor after activation\n");
        // print4DTensor(result_4D_tensor);
        tensor4DMaxPool(&result_4D_tensor[1], 2, 2, 2);
        // printf("tensor after maxpooling\n");
        // print4DTensor(&result_4D_tensor[1]);

    // fully-connected layer 
        tensor4Dflatten(&result_4D_tensor[1]);
        // printf("tensor after flattening\n");
        // print4DTensor(&result_4D_tensor[1]);
        tesor4DFC(&result_4D_tensor[1], &fc_weight[0], &fc_bias[0], &result_matrix[0], al);
        // printf("\ntensor after fc before activation\n");

        // printMatrix(&result_matrix[0]);
        matrixActivation(&result_matrix[0]);
        // printf("\ntensor after fc + activation\n");
        // printMatrix(&result_matrix[0]);

        matrixFC(&result_matrix[0], &fc_weight[1], &fc_bias[1], &result_matrix[1], al);
        // printf("\ntensor after fc before activation\n");
        // printMatrix(&result_matrix[1]);
        matrixActivation(&result_matrix[1]);
        // printf("\ntensor after fc + activation\n");
        // printMatrix(&result_matrix[1]);

        matrixFC(&result_matrix[1], &fc_weight[2], &fc_bias[2], &result_matrix[2], al);
        // printf("\ntensor after fc before activation\n");
        // printMatrix(&result_matrix[2]);
        //matrixActivation(&result_matrix[2]);
        //printf("\ntensor after fc + activation\n");
        // printMatrix(&result_matrix[2]);
#ifdef TEST
        printf("\n ======== result : %d  ==================\n", maxElement(&result_matrix[2]));
#endif
        if (real_label == maxElement(&result_matrix[2])) { 
#ifdef TEST
            printf(" \n======== succsess ==========\n");
#endif
            success_count++;
        }
        else {
#ifdef TEST
            printf("\n ======== failed ==========\n");
#endif
            fail_count++;
        }
    }
    fclose(imageFilePointer);

    printf("total success : %f", success_count / (success_count + fail_count) );

#ifdef VS_MANNIX
    free(data);  // we may use float for the first test infirence
    free(alloc_matrix);
    free(tens);
#endif

    return 0;
}

