
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
    
    #include "../include/mannix_src_setup.h"

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
