#include "../include/cnn_inc.h"

int main() {
     
    #include "../include/tensor_allocation_setup.h"
    Matrix_int8 fc_weight[1];
    creatMatrix_int8(3, 3,  &fc_weight[0],   (Allocator_int8*)  al);
    FILE* fd = fopen("C:\\Users\\eliyahu\\Desktop\\software\\tensorflop\\mannix\\software\\riskv_simul\\source\\matrix.csv","r");
    int label[1]; label[0] = 0; // needed only for matrix with label
    getMatrix_int8(fc_weight, fd, label,-1, 1);
    printMatrix_int8(fc_weight);
    fclose(fd);

    Matrix_int8 cnn_weight[1];
    creatMatrix_int8(2, 2,  &cnn_weight[0],   (Allocator_int8*)  al);
    FILE* fd2 = fopen("C:\\Users\\eliyahu\\Desktop\\software\\tensorflop\\mannix\\software\\riskv_simul\\source\\matrix.csv","r");
    getMatrix_int8(cnn_weight, fd2, label,-1, 1);
    printMatrix_int8(cnn_weight);
    dump_model_params_mfdb(al,MODEL_PARAMS_FILE);  // dump mannix format data base
    fclose(fd2);
    return 0;
}