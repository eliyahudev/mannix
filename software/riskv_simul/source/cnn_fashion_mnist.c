

#include "../include/cnn_inc.h"

int main(int argc, char const *argv[]) {

// like-dynamic memory allocation for the program 
#include "../include/tensor_allocation_setup.h"

    // declare 4D tensors
    Tensor4D_uint8 image[1];
    Tensor4D_int8 conv_weight[2];
    Tensor4D_int32 result_4D_tensor[2];
    Tensor4D_uint8 result_maxPool_tensor[2];
    Tensor4D_uint8 result_4D_tensor_uint8[2];

    // declare matrix bias [for each matrix there is one bias value, for example for image->matrix[0] we add the same value bias->data[0] to all cells]
    Matrix_int32 conv_bias[2];
    
    Matrix_int8 fc_weight[3];
    Matrix_int32 fc_bias[3];
    Matrix_int32 result_matrix[3];
    Matrix_uint8 result_matrix_uint8[3];
    
    // import matrices

    char* path_in = { "../../../python/csv_dumps/scaled_int/" };

#ifndef MEM_LOAD_MODE
  #ifdef VS_MANNIX
      #ifdef CMP_TEST  
      FILE* imageFilePointer = fopen("../../test_src/img_3673.csv", "r");
      char file_out[80] ;
      #else
      FILE* imageFilePointer = fopen("../../test_src/data_set_256_fasion_emnist.csv", "r");
      #endif
      char * path_out = {"../../test_products/"} ;    
  #else
      char* path_in = { "../../python/csv_dumps/scaled_int/" };
      #ifdef CMP_TEST  
      FILE* imageFilePointer = fopen("../../../../test_and_delete/mannix_test/inference/img_csv_dumps/img_3673.csv", "r");
      #else
      FILE* imageFilePointer = fopen("../test_src/data_set_256_fasion_emnist.csv", "r");
      #endif
      char * path_out = {"../test_products/"} ;
  #endif
#else
    FILE* imageFilePointer = fopen(DATASET_FILE,"r");  // @MEM_LOAD_MODE (File name defined at man_def.h)
    char * path_out = {"../test_products/"} ;
    char file_out[80] ;

#endif

    // allocate memory for image, conv_weight and bias
    printf("allocating memory\n");
    create4DTensor_uint8(&image[0], 28, 28, 1, 1,    (Allocator_uint8*)al, (MatAllocator_uint8*)mat_al, (TensorAllocator_uint8*)tens_alloc);  
    create4DTensor_int8(&conv_weight[0], 5, 5, 1, 6, (Allocator_int8*)al, (MatAllocator_int8*)mat_al, (TensorAllocator_int8*)tens_alloc);
    create4DTensor_int8(&conv_weight[1], 5, 5, 6, 12,(Allocator_int8*)al, (MatAllocator_int8*)mat_al, (TensorAllocator_int8*)tens_alloc);
    creatMatrix_int32(6, 1,   &conv_bias[0],   (Allocator_int32*) al);
    creatMatrix_int32(12, 1,  &conv_bias[1],   (Allocator_int32*) al);
    creatMatrix_int8(120, 192,&fc_weight[0],   (Allocator_int8*)  al);
    creatMatrix_int8(64, 120, &fc_weight[1],   (Allocator_int8*)  al);
    creatMatrix_int8(10, 64,  &fc_weight[2],   (Allocator_int8*)  al);
    creatMatrix_int32(120,1,  &fc_bias[0],     (Allocator_int32*) al);
    creatMatrix_int32(64,1,   &fc_bias[1],     (Allocator_int32*) al);
    creatMatrix_int32(10,1,   &fc_bias[2],     (Allocator_int32*) al);
 
    // set values from csv table
    printf("setting weights and bais\n");
    setFilter(&conv_weight[0], path_in, 1);
    setFilter(&conv_weight[1], path_in, 2);
    setBias(&conv_bias[1], path_in, "conv", 2, "b");
    setBias(&conv_bias[0], path_in, "conv", 1, "b");
    setBias(&fc_bias[0], path_in, "fc", 1, "b");
    setBias(&fc_bias[1], path_in, "fc", 2, "b");
    setBias(&fc_bias[2], path_in, "fc", 3, "b");
    setWeight(&fc_weight[0], path_in, "fc", 1, "w");
    setWeight(&fc_weight[1], path_in, "fc", 2, "w");
    setWeight(&fc_weight[2], path_in, "fc", 3, "w");

    
    #ifdef MEM_DUMP_MODE // Dumps the model parameters loadable db , run once per model configuration.
    dump_model_params_mfdb(al,MODEL_PARAMS_FILE);  // dump mannix format data base
    #endif
    
    #ifdef MEM_LOAD_MODE // Load the model parameters pre-dumped db
    load_model_params_mfdb(al,MODEL_PARAMS_FILE);  // load mannix format data base
    #endif
  
    float success_count = 0;
    float fail_count = 0;

    char* reset_mannix_data = al->data;
    int reset_mannix_data_index = al->index ;
    Matrix_uint8* reset_mannix_matrix = mat_al->matrix ;
    int reset_mannix_matrix_index = mat_al->index ;
    Tensor_uint8* reset_mannix_tensor = tens_alloc->tensor ;
    int reset_mannix_tensor_index = tens_alloc->index ;

    printf("============================================================================\n");
    printf("=============== starting test (it could take some time...): ================\n");
    printf("============================================================================\n\n");
  #ifdef TEST
      for (int a = 0; a < 1; a++) {
  #else
      #ifdef CMP_TEST
          for (int a = 0; a < 1; a++) {
      #else
          int i=0;
          while (!feof(imageFilePointer)) {
              if ((i%100)==0) printf("Done checking %d images ...\r",i) ;
              i++ ;
      #endif            
  #endif

        al->data = reset_mannix_data ;
        al->index = reset_mannix_data_index ;
        mat_al->matrix = reset_mannix_matrix ;
        mat_al->index = reset_mannix_matrix_index ;
        tens_alloc->tensor = reset_mannix_tensor ;
        tens_alloc->index = reset_mannix_tensor_index ;

        int real_label = setImage(&image[0], imageFilePointer);
        
        int sc = LOG2_RELU_FACTOR ;  // 'sc' (extra scale) is determined by LOG2_RELU_FACTOR , consider maling this layer specific;

    //  convolution layer 
        
        Tensor4D_uint8 * actResult_4D_tensor = tensor4DConvNActivate(image, &conv_weight[0], &conv_bias[0], result_4D_tensor_uint8, (Allocator_int32 *)al, (MatAllocator_int32 *)mat_al, (TensorAllocator_int32 *)tens_alloc, sc);
        IFDEF_CMP_TEST( writeTensor4DToCsv_uint8 (actResult_4D_tensor, path_out, "conv1_relu_out"); )
 
        Tensor4D_uint8 * maxPoolResult_tensor =  tensor4DMaxPool(actResult_4D_tensor, &result_maxPool_tensor[0], 2, 2, 2, al, mat_al, tens_alloc);
       
        IFDEF_CMP_TEST( writeTensor4DToCsv_uint8 (maxPoolResult_tensor, path_out, "conv1_pool2d_out"); )
      
        actResult_4D_tensor = tensor4DConvNActivate(maxPoolResult_tensor, &conv_weight[1], &conv_bias[1], &result_4D_tensor_uint8[1], (Allocator_int32 *)al, (MatAllocator_int32 *)mat_al, (TensorAllocator_int32 *)tens_alloc, sc);

        IFDEF_CMP_TEST( writeTensor4DToCsv_uint8 (actResult_4D_tensor  , path_out, "conv2_relu_out"); )

        maxPoolResult_tensor =  tensor4DMaxPool(actResult_4D_tensor, & result_maxPool_tensor[1], 2, 2, 2, al, mat_al, tens_alloc);
     
        IFDEF_CMP_TEST( writeTensor4DToCsv_uint8 (maxPoolResult_tensor, path_out, "conv2_pool2d_out"); )


    // fully-connected layer 

        tensor4Dflatten(maxPoolResult_tensor);
        
        Matrix_uint8 * actResultMatrix  = matrixFCNActivate(maxPoolResult_tensor->tensor->matrix, &fc_weight[0], &fc_bias[0], &result_matrix_uint8[0], (Allocator_int32 *)al, sc);

        IFDEF_CMP_TEST(strcpy(file_out,path_out);writeMatrixToCsv_uint8(actResultMatrix,strcat(file_out,"fc1_relu_out.csv")); ) 
        
        actResultMatrix  = matrixFCNActivate(&result_matrix_uint8[0], &fc_weight[1], &fc_bias[1], &result_matrix_uint8[1], (Allocator_int32 *)al, sc);

        IFDEF_CMP_TEST(strcpy(file_out,path_out);writeMatrixToCsv_uint8(actResultMatrix,strcat(file_out,"fc2_relu_out.csv")); ) 

        actResultMatrix  = matrixFCNActivate(&result_matrix_uint8[1], &fc_weight[2], &fc_bias[2], &result_matrix_uint8[2], (Allocator_int32 *)al, sc);
        
        IFDEF_CMP_TEST(strcpy(file_out,path_out);writeMatrixToCsv_uint8(&result_matrix_uint8[2],strcat(file_out,"fc3_out.csv")); ) 

        int detected_label = maxElement_uint8(&result_matrix_uint8[2]) ;
#ifdef TEST
        printf("\n ======== result : %d  ==================\n", detected_label);
#endif
        if (real_label == detected_label) { 
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

//#ifndef MEM_LOAD_MODE
    fclose(imageFilePointer);
//#endif

    printf("\ndone!\n======================= total success : %f ========================\n", (float)(100* success_count) / (float)(success_count + fail_count));

return 0;
}

