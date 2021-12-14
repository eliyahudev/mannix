#include "../include/cnn_inc.h"

int main() {
     
    #include "../include/tensor_allocation_setup.h"
    Matrix_int8 fc_weight[1];
    creatMatrix_int8(4, 3,  &fc_weight[0],   (Allocator_int8*)  al);
    FILE* fd = fopen("TODO - add full path to matrix.csv","r");
    int label[1]; label[0] = 0; // needed only for matrix with label
    getMatrix_int8(fc_weight, fd, label,-1, 1);
    printMatrix_int8(fc_weight);
    return 0;
}