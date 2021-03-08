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


void addTensor(Tensor* tens1, Tensor* tens2) {
    if(tens1->depth != tens2->depth) {
        printf("DImension ERRER - Tensors depth is not equal\n");
        exit(-1);
    }
    for(int i = 0; i < tens1->depth; i++) {
        addMatrix(&tens1->matrix[i], &tens2->matrix[i]);
    }
}
 

void printTensor(Tensor* tens) {

    for(int i = 0; i < tens->depth; i++) {
        printMatrix(&tens->matrix[i]);
        if(i!= tens->depth-1) 
            printf("\n,\n");
        
    }
}


void writeTensorToCsv (Tensor* tens, char* file_path) {
    
    char path[60];
    char cast_int[3]; // todo - add "warning this function hendle up to 3 digit layer"  

    for (size_t i = 0; i < tens->depth; i++) {
        strcpy(path, file_path);
        strcat(path,"_");
        itoa(i, cast_int, 10);
        strcat(path,cast_int);
        strcat(path,".csv");
        writeMatrixToCsv (&tens->matrix[i], path);
    }
}


void tensorFlatten(Tensor* tens, int n_row) {
    
    tens->rows  = n_row;
    tens->cols  = 1;
    tens->depth = 1;
    setMatrixSize(&tens->matrix[0], tens->rows, tens->cols);
}


Matrix* TensorToMatrix(Tensor* tens) { return tens->matrix;}

// ================= NN functions ============================


// maxpuling matrix
// set data and reshap the matrix to the new size
// p_m - window's hight
// p_n - window's depth
Tensor* tensorMaxPool(Tensor *tens, /*TODO add result_tens,*/int p_m, int p_n, int stride){
    
    //set filter's window movment
    int new_rows = (tens->rows - p_m) / stride + 1;
    int new_cols = (tens->cols - p_m) / stride + 1;
    int k = 0;
    for(int d = 0; d < tens->depth; d++) {
        // matrixMaxPool(&tens->matrix[d], p_m, p_n, stride);
        // set data
        for (int i=0; i < new_rows; i++) {
            for (int j=0; j < new_cols; j++) {
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


void tensorActivation(Tensor *tens, int sc) {
    for (size_t i = 0; i < tens->depth; i++) {
        matrixActivation(&tens->matrix[i], sc);
    }
}


Matrix* tensorConvolution(Tensor* tens, Tensor* m_filter, DATA_TYPE bias, Matrix* result_matrix, Allocator* al, MatAllocator* mat_alloc){

    Matrix tmp_matrix[1];

    creatMatrix(tens->rows - m_filter->rows + 1, tens->cols - m_filter->cols + 1, tmp_matrix, al);  // todo - delete after debuging    

    for (size_t i = 0; i < tens->depth; i++) {
        matrixConvolution(&tens->matrix[i], &m_filter->matrix[i], bias, tmp_matrix);
        addMatrix(result_matrix, tmp_matrix);
    }
    // delete allocation
    mannixDataFree(al, tmp_matrix->data, tmp_matrix->size);
    
    return result_matrix;
}


Matrix* tesorFC(Tensor* tens, Matrix* weight_matrix, Matrix* bias_vector, Matrix* result_matrix, Allocator* al) {
    matrixFC(&tens->matrix[0] , weight_matrix, bias_vector, result_matrix, al);
    return &tens->matrix[0];
}    
#endif