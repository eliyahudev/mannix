#include "../include/cnn_inc.h"

int main(int argc, char const *argv[]) {
  
// declare 4D tensors arrays
  Tensor4D_uint8 input[1];
  Tensor4D_int8 conv_weight[1];
  Tensor4D_uint8 result_tensor[1];
  Matrix_int32 conv_bias[2];
  Matrix_int8 fc_weight[3];
  Matrix_int32 fc_bias[3];
  Matrix_int32 result_matrix[3];
  Matrix_uint8 result_matrix_uint8[3];

  char* path_in = { "../../../python/csv_dumps/scaled_int/" };
  FILE* imageFilePointer = fopen("../test_src/data_set_256_fasion_emnist.csv", "r");  // input file 
  char file_out[80];
  char * path_out = {"../test_products/"};

  // allocate memory for image, conv_weight and bias
  printf("allocating memory\n");
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
  create4DTensor_uint8(&image[0], 28, 28, 1, 1,    (Allocator_uint8*)al, (MatAllocator_uint8*)mat_al, (TensorAllocator_uint8*)tens_alloc);

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
  dump_model_params_mfdb(al,MODEL_PARAMS_FILE);  // dump mannix format data base
  return 0;
}
