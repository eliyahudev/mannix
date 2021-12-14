#include "../include/cnn_inc.h"

int main() {
     
    #include "../include/tensor_allocation_setup.h"
    Matrix_uint8 input_mat[1];
    Matrix_int8 conv_filter[1];
    Matrix_int32 conv_bias[1];
    Matrix_uint8 result_mat[1];

    // C'tor like functions
    creatMatrix_uint8(4, 1,  &input_mat[0],   (Allocator_uint8*)  al);
    creatMatrix_int8(4, 4,  &conv_filter[0],   (Allocator_int8*)  al);
    creatMatrix_int32(4, 1,  &conv_bias[0],   (Allocator_int32*)  al);

    // load data from csv
    FILE* fd = fopen("../examples/input_vector.csv","r");
    FILE* fd_filter = fopen("../examples/fc_weights.csv","r");
    FILE* fd_bias = fopen("../examples/bias_vector.csv","r");

    int label[1]; label[0] = 0; // needed only for matrix with label

    getMatrix_uint8(input_mat, fd, label,-1, 1);
    getMatrix_int8(conv_filter, fd_filter, label,-1, 1);
    getMatrix_int32(conv_bias, fd_bias, label,-1, 1);

    // Matrix fc 
    // Matrix_uint8* matrixFCNActivate(Matrix_uint8* input_matrix, Matrix_int8* weight_matrix, Matrix_int32* bias_vector, Matrix_uint8* result_matrix, Allocator_int32* al, int sc) {
    matrixFCNActivate(input_mat, conv_filter, conv_bias, result_mat, (Allocator_int32*) al, 1);

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
    printMatrix_uint8(result_mat);

    return 0;
}