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
    printf("test===============================================");
    creatMatrix((m1->rows - p_m) / stride + 1 ,(m1->cols - p_m) / stride + 1, result_matrix, al);
    for (int i=0; i < result_matrix->rows + 1; i = i++) {
        for (int j=0; j < result_matrix->cols + 1; j = j++) {
            result_matrix->data[i*result_matrix->cols + j] = getMax(m1, result_matrix, p_m, p_n, i, j, stride);
        }
    }
    return result_matrix;
}


#endif // CNN_H
