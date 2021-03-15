#include "../include/cnn_inc.h"


int main(int argc, char const *argv[]) {

// like-dynamic memory allocation for the program 
#include "../include/tensor_allocation_setup.h"

    // declare 4D tensors
    Tensor4D image[1];
    Tensor4D conv_weight[2];
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
    #ifdef CMP_TEST  
    FILE* imageFilePointer = fopen("../../../../test_and_delete/mannix_test/inference/img_csv_dumps/img_9558.csv", "r");
    #else
    FILE* imageFilePointer = fopen("../test_src/data_set_256_fasion_emnist.csv", "r");
    #endif
#endif
    // allocate memory for image, conv_weight and bias
    printf("allocating memory\n");
    create4DTensor(&image[0], 28, 28, 1, 1, al, mat_al, tens_alloc);
    create4DTensor(&conv_weight[0], 5, 5, 1, 6, al, mat_al, tens_alloc);
    create4DTensor(&conv_weight[1], 5, 5, 6, 12, al, mat_al, tens_alloc);
    creatMatrix(6, 1, &conv_bias[0], al);
    creatMatrix(12, 1, &conv_bias[1], al);
    creatMatrix(120, 192, &fc_weight[0], al);
    creatMatrix(64, 120, &fc_weight[1], al);
    creatMatrix(10, 64, &fc_weight[2], al);
    creatMatrix(120,1, &fc_bias[0], al);
    creatMatrix(64,1, &fc_bias[1], al);
    creatMatrix(10,1, &fc_bias[2], al);
    
    // set values from csv table
    printf("setting weights and bais\n");
    setFilter(&conv_weight[0], path, 1);
    setFilter(&conv_weight[1], path, 2);
    setBias(&conv_bias[1], path, "conv", 2, "b");
    setBias(&conv_bias[0], path, "conv", 1, "b");
    setBias(&fc_bias[0], path, "fc", 1, "b");
    setBias(&fc_bias[1], path, "fc", 2, "b");
    setBias(&fc_bias[2], path, "fc", 3, "b");
    setWeight(&fc_weight[0], path, "fc", 1, "w");
    setWeight(&fc_weight[1], path, "fc", 2, "w");
    setWeight(&fc_weight[2], path, "fc", 3, "w");

    float success_count = 0;
    float fail_count = 0;

    DATA_TYPE* reset_mannix_data = al->data;
    int reset_mannix_data_index = al->index ;
    Matrix* reset_mannix_matrix = mat_al->matrix ;
    int reset_mannix_matrix_index = mat_al->index ;
    Tensor* reset_mannix_tensor = tens_alloc->tensor ;
    int reset_mannix_tensor_index = tens_alloc->index ;

    printf("starting test (it could take sum time...):\n");
#ifdef TEST
    for (int a = 0; a < 100; a++) {
#else
    #ifdef CMP_TEST
        for (int a = 0; a < 1; a++) {
    #else
        while (!feof(imageFilePointer)) {
    #endif            
#endif
        al->data = reset_mannix_data ;
        al->index = reset_mannix_data_index ;
        mat_al->matrix = reset_mannix_matrix ;
        mat_al->index = reset_mannix_matrix_index ;
        tens_alloc->tensor = reset_mannix_tensor ;
        tens_alloc->index = reset_mannix_tensor_index ;

        int real_label = setImage(&image[0], imageFilePointer);

    //  convolution layer 
        tensor4DConvolution(image, conv_weight, conv_bias, result_4D_tensor, al, mat_al, tens_alloc);
#ifdef CMP_TEST       
    #ifdef VS_MANNIX
            writeTensor4DToCsv (&result_4D_tensor[0], "../../test_products/", "conv1_out");
    #else
            writeTensor4DToCsv (&result_4D_tensor[0], "../test_products/", "conv1_out");
    #endif 
#endif 
        tensor4DActivation(result_4D_tensor,3);
#ifdef CMP_TEST       
    #ifdef VS_MANNIX
            writeTensor4DToCsv (&result_4D_tensor[0], "../../test_products/", "conv1_relu_out");
    #else
            writeTensor4DToCsv (&result_4D_tensor[0], "../test_products/", "conv1_relu_out");
    #endif 
#endif 
        tensor4DMaxPool(result_4D_tensor, 2, 2, 2);
#ifdef CMP_TEST       
    #ifdef VS_MANNIX
            writeTensor4DToCsv (&result_4D_tensor[0], "../../test_products/", "conv1_pool2d_out");
    #else
            writeTensor4DToCsv (&result_4D_tensor[0], "../test_products/", "conv1_pool2d_out");
    #endif 
#endif 

        tensor4DConvolution(&result_4D_tensor[0], &conv_weight[1], &conv_bias[1], &result_4D_tensor[1], al, mat_al, tens_alloc);
#ifdef CMP_TEST       
    #ifdef VS_MANNIX
            writeTensor4DToCsv (&result_4D_tensor[1], "../../test_products/", "conv2_out");
    #else
            writeTensor4DToCsv (&result_4D_tensor[1], "../test_products/", "conv2_out");
    #endif 
#endif
        tensor4DActivation(&result_4D_tensor[1],3/*,*/);
#ifdef CMP_TEST       
    #ifdef VS_MANNIX
            writeTensor4DToCsv (&result_4D_tensor[1], "../../test_products/", "conv2_relu_out");
    #else
            writeTensor4DToCsv (&result_4D_tensor[1], "../test_products/", "conv2_relu_out");
    #endif 
#endif
        tensor4DMaxPool(&result_4D_tensor[1], 2, 2, 2);
#ifdef CMP_TEST       
    #ifdef VS_MANNIX
            writeTensor4DToCsv (&result_4D_tensor[1], "../../test_products/", "conv2_pool2d_out");
    #else
            writeTensor4DToCsv (&result_4D_tensor[1], "../test_products/", "conv2_pool2d_out");
    #endif 
#endif
    // fully-connected layer 
        tensor4Dflatten(&result_4D_tensor[1]);
        tesor4DFC(&result_4D_tensor[1], &fc_weight[0], &fc_bias[0], &result_matrix[0], al);
        matrixActivation(&result_matrix[0], 3);

        matrixFC(&result_matrix[0], &fc_weight[1], &fc_bias[1], &result_matrix[1], al);
        matrixActivation(&result_matrix[1], 3);

        matrixFC(&result_matrix[1], &fc_weight[2], &fc_bias[2], &result_matrix[2], al);
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
    printf(" done!\n ======================= total success : %f ========================\n", success_count / (success_count + fail_count) * 100);

#ifdef VS_MANNIX
    free(data);  // we may use float for the first test infirence
    free(alloc_matrix);
    free(tens);
#endif

    return 0;
}

