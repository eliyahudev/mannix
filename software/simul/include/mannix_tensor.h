#ifndef MANNIX_TENSOR
#define MANNIX_TENSOR


void createTensor(int rows, int cols, int depth, Tensor* tens, Allocator* al, MatAllocator* mat_alloc) {

    tens->rows = rows;
    tens->cols = cols;
    tens->depth = depth;
    tens->matrix = mannixMatrixMalloc(mat_alloc, depth);
    for(int i = 0; i < depth; i++) {
        creatMatrix(rows, cols, &tens->matrix[i], al);
    } 
}



// todo - maybe irrelevant
void setMatrixToTensor(Tensor* tens, FILE* filePointer, int* label, int op) {
    for (int i = 0; i < tens->depth; i++) {
        setMatrixValues(&tens->matrix[i], filePointer, label, op);
        // getData(filePointer, tens->matrix[i]->size + 1, label, tens->matrix[i]->data);
    }
}

void tensorFlatten(Tensor* tens) {
    int new_row = tens->rows * tens->cols * tens->depth;
    tens->matrix->rows = new_row;
    tens->matrix->cols = 1;
    tens->rows = new_row;
    tens->cols = 1;
    tens->depth = 1;
}

void addTensor(Tensor* tens1, Tensor* tens2) {
    if(tens1->depth != tens2->depth) {
        printf("DImension ERRER - Tensors depth is not equal\n");
        exit(-1);
    }
    for(int i = 0; i < tens1->depth; i++) {
        addMatrix(&tens1->matrix[i], &tens2->matrix[i]);
    }
}

// void mullTensor(Tensor* tens1, Tensor* tens2) {
//     if(tens1->depth != tens2->depth) {
//         printf("DImension ERRER - Tensors depth is not equal\n");
//         exit(-1);
//     }
//     for(int i = 0; i < tens1->depth; i++) {
//         mullMatrix(&tens1->matrix[i], &tens2->matrix[i]);
//     }
// }
 

void printTensor(Tensor* tens) {

    for(int i = 0; i < tens->depth; i++) {
        printMatrix(&tens->matrix[i]);
        if(i!= tens->depth-1) 
            printf("\n,\n");
        
    }
}

Matrix* TensorToMatrix(Tensor* tens) { return tens->matrix;}

// ================= CNN functions ============================

// TODO add a stride like in maxpool

// mull and sum:
// multiple window by the filter 
// and return the sum of the window 
// Tensor* tensorConvolution(Tensor *tens, Tensor* m_filter, Tensor*  tmp_tens, Allocator* al){
//     createTensor(m1->rows - m_filter-> rows + 1 ,m1->cols - m_filter->cols + 1, tmp_tens, al);
//     for (size_t d = 0; d < count; d++) {
//         matrixConvolution(Matrix* m1, Matrix* m_filter, Matrix* result_matrix, Allocator* al);

//     }
    
//     return result_matrix;
// }


// maxpuling matrix
// set data and reshap the matrix to the new size
// p_m - window's hight
// p_n - window's depth
Tensor* tensorMaxPool(Tensor *tens, int p_m, int p_n, int stride){
    
    //set filter's window movment
    int new_rows = (tens->rows - p_m) / stride + 1;
    int new_cols = (tens->cols - p_m) / stride + 1;
    int k = 0;
    for(int d = 0; d < tens->depth; d++) {
        
        // set data
        for (int i=0; i < new_rows; i = i++) {
            for (int j=0; j < new_cols; j = j++) {
                tens->matrix[0].data[k++] = getMax(&tens->matrix[d], p_m, p_n, i, j, stride);
            }
        }
        tens->matrix[d].data = tens->matrix[0].data + (new_rows * new_cols * d); 
        // set dimension
        tens->matrix[d].rows = new_rows;
        tens->matrix[d].cols = new_cols;
    }
    tens->rows = new_rows;
    tens->cols = new_cols;

    return tens;
}


// todo - change to Udi's ReLu method
void mannixRelu(Matrix* m1) {

    for (int i=0; i < m1->rows; i++) {
        for (int j=0; j < m1->cols; j++) {
            if (m1->data[i*m1->cols + j] < 0)
                m1->data[i*m1->cols + j] = 0;
            else
                m1->data[i*m1->cols + j]  >> 8;
        }
    }
}


void fullyConnected(Matrix* input_matrix, Matrix* weight_matrix, Matrix* bias_vector, Matrix* result_matrix, Allocator* al) {
        matrixToVector(input_matrix);
        mullMatrix(weight_matrix, input_matrix, result_matrix,al);
        addMatrix(result_matrix, bias_vector);
}

#endif