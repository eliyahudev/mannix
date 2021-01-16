#ifndef CNN_H
#define CNN_H

// TODO add stide like in maxpool

// mull and sum:
// multiple window by the filter 
// and return the sum of the window 
Matrix* mns(Matrix* m1, Matrix* m_filter, Matrix* result_matrix, Allocator* al){

    creatMatrix(m1->rows - m_filter-> rows + 1 ,m1->cols - m_filter->cols + 1, result_matrix, al);
    for (int i=0; i < result_matrix->rows + 1; i++) {
        for (int j=0; j < result_matrix->cols + 1; j++) {
            result_matrix->data[i*result_matrix->cols + j] = hadamardMullMatrix(m1, m_filter, result_matrix, i, j);
        }
    }
    return result_matrix;
}

// maxpuling 
// p_m - window's hight
// p_n - window's width
Matrix* maxPull(Matrix* m1, Matrix* result_matrix, Allocator* al, int p_m, int p_n, int stride){

    creatMatrix((m1->rows - p_m) / stride + 1 ,(m1->cols - p_m) / stride + 1, result_matrix, al);
    for (int i=0; i < result_matrix->rows + 1; i = i++) {
        for (int j=0; j < result_matrix->cols + 1; j = j++) {
            result_matrix->data[i*result_matrix->cols + j] = getMax(m1, p_m, p_n, i, j, stride);
        }
    }
    return result_matrix;
}

void mannixRalu(Matrix* m1) {

    for (int i=0; i < m1->rows; i++) {
        for (int j=0; j < m1->cols; j++) {
            if (m1->data[i*m1->cols + j] < 0)
                m1->data[i*m1->cols + j] = 0;
            else
                m1->data[i*m1->cols + j]  >> 8;
        }
    }
}

// ------------------------------------ MANNIX FUNCTIONS -------------------------------------------------
void cnnConvolutionLayer(Matrix* input_matrix, Matrix* weight_matrix, Matrix* result_matrix, Allocator* al) {

    #ifdef MANNIX_CNN_F
        volatile signed start = 1;
        volatile signed done = 0; 
        while (start)
            MANNIX_convolution_layer(input_matrix->data, weight_matrix->data, result_matrix->data, input_matrix->rows, input_matrix->cols,
                weight_matrix->rows, weight_matrix->cols, start, done);
        while (!done); 
    #else
        mns(input_matrix, weight_matrix, result_matrix, al);
    #endif

    #ifdef TEST
        printMatrix(result_matrix);
    #endif
}

void  nonLinearityActivation(Matrix* input_matrix){

    #ifdef MANNIX_ACTIVE_F
        volatile signed start = 1;
        volatile signed done = 0; 
        while (start)
            MANNIX_non_linearity_activation(input_matrix->data, input_matrix->rows, input_matrix->cols, start, done);
        while (!done); 
    #else
        mannixRalu(input_matrix);
    #endif

    #ifdef TEST
        printMatrix(input_matrix);
    #endif
}

void pullLayer(Matrix* input_matrix, Matrix* result_matrix, Allocator* al, int p_m, int p_n, int stride) {
    #ifdef MANNIX_PULL_F
        volatile signed start = 1;
        volatile signed done = 0; 
        while (start)
            MANNIX_pull_layer(input_matrix->data, input_matrix->rows, input_matrix->cols, p_m, p_n, start, done);
        while (!done); 
    #else
        maxPull(input_matrix, result_matrix, al, p_m, p_n, stride);
    #endif
    
    #ifdef TEST
        printMatrix(result_matrix);
    #endif
}

void fc(Matrix* input_matrix, Matrix* weight_matrix, Matrix* bais_vector, Matrix* result_matrix, Allocator* al) {
    #ifdef MANNIX_FC_F
        volatile signed start = 1;
        volatile signed done = 0; 
        while (start)
            MANNIX_fully_conneted();
        while (!done); 
    #else
        matrixToVector(input_matrix);
        mullMatrix(weight_matrix, input_matrix, result_matrix,al);
        addMatrix(result_matrix, bias_vector);
    #endif

}
#endif // CNN_H

// todo - create multiple filter function for convolution