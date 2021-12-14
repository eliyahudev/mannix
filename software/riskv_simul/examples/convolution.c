#include "../include/cnn_inc.h"

int main() {
     
    #include "../include/tensor_allocation_setup.h"
    Matrix_uint8 input_mat[1];
    Matrix_int8 conv_filter[1];
    Matrix_int32 conv_bias[1];
    Matrix_int32 result_mat[1];

    // C'tor like functions
    creatMatrix_uint8(4, 4,  &input_mat[0],   (Allocator_uint8*)  al);
    creatMatrix_int8(3, 3,  &conv_filter[0],   (Allocator_int8*)  al);
    creatMatrix_int32(1, 1,  &conv_bias[0],   (Allocator_int32*)  al);
    creatMatrix_int32(2, 2,  &result_mat[0],   (Allocator_int32*)  al);

    // load data from csv
    FILE* fd = fopen("../examples/matrix.csv","r");
    FILE* fd_filter = fopen("../examples/filter.csv","r");
    FILE* fd_bias = fopen("../examples/bias.csv","r");

    int label[1]; label[0] = 0; // needed only for matrix with label

    getMatrix_uint8(input_mat, fd, label,-1, 1);
    getMatrix_int8(conv_filter, fd_filter, label,-1, 1);
    getMatrix_int32(conv_bias, fd_bias, label,-1, 1);

    // Matrix convolution 
    matrixConvolution(input_mat, conv_filter, conv_bias->data[0], result_mat);
    
    // print results
    printf("printMatrix_int8(input_mat):\n");
    printMatrix_uint8(input_mat);
    
    printf("\n\n");
    printf("printMatrix_int8(conv_filter):\n");
    printMatrix_int8(conv_filter);
    
    printf("\n\n");
    printf("printMatrix_int32(conv_bias):\n");
    printMatrix_int32(conv_bias);

    printf("\n\n");
    printf("printMatrix_int32(result_mat):\n");
    printMatrix_int32(result_mat);

    return 0;
}