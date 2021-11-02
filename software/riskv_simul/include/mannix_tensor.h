#ifndef MANNIX_TENSOR
#define MANNIX_TENSOR


void createTensor_uint8(int rows, int cols, int depth, Tensor_uint8* tens, Allocator_uint8* al, MatAllocator_uint8* mat_alloc) {

    tens->rows = rows;
    tens->cols = cols;
    tens->depth = depth;
    tens->matrix = mannixMatrixMalloc_uint8(mat_alloc, depth);
    for(int i = 0; i < depth; i++) {
        creatMatrix_uint8(rows, cols, &tens->matrix[i], al);
    } 
}


void createTensor_int8(int rows, int cols, int depth, Tensor_int8* tens, Allocator_int8* al, MatAllocator_int8* mat_alloc) {

    tens->rows = rows;
    tens->cols = cols;
    tens->depth = depth;
    tens->matrix = mannixMatrixMalloc_int8(mat_alloc, depth);
    for(int i = 0; i < depth; i++) {
        creatMatrix_int8(rows, cols, &tens->matrix[i], al);
    } 
}


void createTensor_int32(int rows, int cols, int depth, Tensor_int32* tens, Allocator_int32* al, MatAllocator_int32* mat_alloc) {

    tens->rows = rows;
    tens->cols = cols;
    tens->depth = depth;
    tens->matrix = mannixMatrixMalloc_int32(mat_alloc, depth);
    for(int i = 0; i < depth; i++) {
        creatMatrix_int32(rows, cols, &tens->matrix[i], al);
    } 
}



// todo - maybe irrelevant
void setMatrixToTensor_uint8(Tensor_uint8* tens, FILE* filePointer, int* label, int op) {
    for (int i = 0; i < tens->depth; i++) {
        setMatrixValues_uint8(&tens->matrix[i], filePointer, label, op);
        // getData(filePointer, tens->matrix[i]->size + 1, label, tens->matrix[i]->data);
    }
}


void addTensor_int32(Tensor_int32* tens1, Tensor_int32* tens2) {
    if(tens1->depth != tens2->depth) {
        printf("DImension ERRER - Tensors depth is not equal\n");
        exit(-1);
    }
    for(int i = 0; i < tens1->depth; i++) {
        addMatrix_int32(&tens1->matrix[i], &tens2->matrix[i]);
    }
}
 

void printTensor_int32(Tensor_int32* tens) {

    for(int i = 0; i < tens->depth; i++) {
        printMatrix_int32(&tens->matrix[i]);
        if(i!= tens->depth-1) 
            printf("\n,\n");        
    }
}


void printTensor_uint8(Tensor_uint8* tens) {

    for(int i = 0; i < tens->depth; i++) {
        printMatrix_uint8(&tens->matrix[i]);
        if(i!= tens->depth-1) 
            printf("\n,\n");        
    }
}

void printTensor_int8(Tensor_int8* tens) {

    for(int i = 0; i < tens->depth; i++) {
        printMatrix_int8(&tens->matrix[i]);
        if(i!= tens->depth-1) 
            printf("\n,\n");        
    }
}

void writeTensorToCsv_int32 (Tensor_int32* tens, char* file_path) {
    
    char path[60];
    char cast_int[3]; // todo - add "warning this function hendle up to 3 digit layer"  

    for (int i = 0; i < tens->depth; i++) {
        strcpy(path, file_path);
        strcat(path,"_");
        itoa(i, cast_int, 10);
        strcat(path,cast_int);
        #ifdef CSV        
        strcat(path,".csv");
        #else
        strcat(path,".txt");
        #endif
        writeMatrixToCsv_int32 (&tens->matrix[i], path);
    }
}


void writeTensorToCsv_uint8 (Tensor_uint8* tens, char* file_path) {
    
    char path[60];
    char cast_int[3]; // todo - add "warning this function hendle up to 3 digit layer"  

    for (int i = 0; i < tens->depth; i++) {
        strcpy(path, file_path);
        strcat(path,"_");
        itoa(i, cast_int, 10);
        strcat(path,cast_int);
        #ifdef CSV        
        strcat(path,".csv");
        #else
        strcat(path,".txt");
        #endif
        writeMatrixToCsv_uint8 (&tens->matrix[i], path);
    }
}


void tensorFlatten(Tensor_uint8* tens, int n_row) {
    for (int i = 1; i < tens->depth; i++) {
        for (int data = 0; data < tens->matrix->size; data++) {
            tens->matrix->data[i*tens->matrix->size  + data] = tens->matrix[i].data[data];
        }
    }
    
    tens->rows  = n_row;
    tens->cols  = 1;
    tens->depth = 1;
    setMatrixSize_uint8(&tens->matrix[0], tens->rows, tens->cols);
}


Matrix_uint8* TensorToMatrix(Tensor_uint8* tens) { return tens->matrix;}

// ================= NN functions ============================


Tensor_uint8* tensorMaxPool_uint8(Tensor_uint8 *tens, Tensor_uint8 *tens_result, int p_m, int p_n, int stride){
    
    for(int d = 0; d < tens->depth; d++) {
        matrixMaxPool(&tens->matrix[d], &tens_result->matrix[d], p_m, p_n, stride);
    }
    return tens;
}


Tensor_uint8  * tensorActivation(Tensor_int32 *tens, int sc) {
       
    for (int i = 0; i < tens->depth; i++) {
      matrixActivation(&tens->matrix[i], sc);
    }
    return (Tensor_uint8  *) tens ;
}

Matrix_int32* tensorConvolution(Tensor_uint8* tens, Tensor_int8* m_filter, int bias, Matrix_int32* result_matrix, Allocator_int32* al, MatAllocator_int32* mat_alloc){

    Matrix_int32 tmp_matrix[1];

    creatMatrix_int32(tens->rows - m_filter->rows + 1, tens->cols - m_filter->cols + 1, tmp_matrix, al);      

    for (int i = 0; i < tens->depth; i++) {
        matrixConvolution(&tens->matrix[i], &m_filter->matrix[i], bias, tmp_matrix);
        addMatrix_int32(result_matrix, tmp_matrix);
    }
    // delete allocation
        printf("error bef\n");

    mannixDataFree_int32(al, tmp_matrix->data, tmp_matrix->pad_size);
            printf("error af\n");

    return result_matrix;
}


Matrix_uint8* tensorConvNActivate(Tensor_uint8* tens, Tensor_int8* m_filter, int bias, Matrix_uint8* result_matrix, Allocator_int32* al, MatAllocator_int32* mat_alloc, int sc){

    Matrix_int32 tmp_matrix[1];
    Matrix_int32 sum_matrix[1];
    
    creatMatrix_int32(tens->rows - m_filter->rows + 1, tens->cols - m_filter->cols + 1, sum_matrix, al);
    creatMatrix_int32(tens->rows - m_filter->rows + 1, tens->cols - m_filter->cols + 1, tmp_matrix, al);     

    int i = 0;

    for (; i < tens->depth-1; i++) {
        matrixConvolution(&tens->matrix[i], &m_filter->matrix[i], 0, tmp_matrix);     
        if (0 == i) {
            asignMatrix_int32(sum_matrix, tmp_matrix);
        }
        else {
            addMatrix_int32(sum_matrix, tmp_matrix);
        }
    }

    matrixConvolution(&tens->matrix[tens->depth-1], &m_filter->matrix[tens->depth-1], bias, tmp_matrix);
    if (0 == i) {
        asignMatrix_uint8(result_matrix, matrixActivation(tmp_matrix, sc));
    }
    else {
        matrixAddNActivate(sum_matrix, tmp_matrix, result_matrix, sc);  
    }
    // free allocation
    mannixDataFree_int32(al, tmp_matrix->data, tmp_matrix->pad_size);
    mannixDataFree_int32(al, sum_matrix->data, sum_matrix->pad_size);
    return result_matrix;
}



#endif

