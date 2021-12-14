
#include "../include/cnn_inc.h"

int main() {

#include "../include/tensor_allocation_setup.h"
Matrix_uint8 input_mat[1];
Matrix_uint8 result_mat[1];
// C'tor like functions
creatMatrix_uint8(4, 4,  &input_mat[0],   (Allocator_uint8*)  al);
creatMatrix_uint8(2, 2,  &result_mat[0],   (Allocator_uint8*)  al);

// load data from csv
FILE* fd = fopen("../examples/matrix.csv","r");

int label[1]; label[0] = 0; // needed only for matrix with label

getMatrix_uint8(input_mat, fd, label,-1, 1);

// Matrix maxpolling 
// Matrix_uint8* matrixMaxPool(Matrix_uint8* m1, Matrix_uint8* m2, int p_m, int p_n, int stride){
matrixMaxPool(input_mat, result_mat, 2, 2, 2);

// print results
printf("printMatrix_uint8(input_mat):\n");
printMatrix_uint8(input_mat);

printf("\n\n");
printf("printMatrix_uint8(result_mat):\n");
printMatrix_uint8(result_mat);

return 0;
}
