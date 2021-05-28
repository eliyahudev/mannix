#ifndef CNN_H
#define CNN_H

//mannix accelerator functions

/*Tensor4D_uint8**/void* tensor4DConvNActivate(Tensor4D_uint8* tens, Tensor4D_int8* filter, Matrix_int32* bias,
                             Tensor4D_uint8* result_4D_tensor, int sc) 
{


    // return result_4D_tensor;
}


/*Tensor4D_uint8**/void* ACCELERATOR_tensor4DMaxPool(Tensor4D_uint8* tens_4d, Tensor4D_uint8* tens_4d_result, int p_m, int p_n, int stride) {
    

    // return tens_4d_result;
}


/*Matrix_uint8**/void* ACCELERATOR_matrixFCNActivate(Matrix_uint8* input_matrix, Matrix_int8* weight_matrix, Matrix_int32* bias_vector, Matrix_uint8* result_matrix, int sc) {

    creatMatrix_uint8(weight_matrix->rows, input_matrix->cols, result_matrix, (Allocator_uint8*) al);     


    // return result_matrix;
}

#endif // CNN_H

