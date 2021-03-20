#ifndef MANNIX_MATRIX
#define MANNIX_MATRIX


// ================== matrix functions ========================
    // ------------------matrix creation -------------------------
    // cearte matrix with the value of zero 
Matrix_int32* creatMatrix_int32(int rows, int cols, Matrix_int32* m1, Allocator_int32* al) {
        m1[0].cols = cols;
        m1[0].rows = rows;
        m1->size = cols * rows;
        m1[0].data = mannixDataMalloc_int32(al, cols * rows);
        for (int i = 0; i < m1->size; i++) {
            m1[0].data[i] = 0 ;
        }
        return m1;
    }
    

Matrix_int8* creatMatrix_int8(int rows, int cols, Matrix_int8* m1, Allocator_int8* al) {
        m1[0].cols = cols;
        m1[0].rows = rows;
        m1->size = cols * rows;
        m1[0].data = mannixDataMalloc_int8(al, cols * rows);
        for (int i = 0; i < m1->size; i++) {
            m1[0].data[i] = 0 ;
        }
        return m1;
    }


Matrix_uint8* creatMatrix_uint8(int rows, int cols, Matrix_uint8* m1, Allocator_uint8* al) {
        m1[0].cols = cols;
        m1[0].rows = rows;
        m1->size = cols * rows;
        m1[0].data = mannixDataMalloc_uint8(al, cols * rows);
        for (int i = 0; i < m1->size; i++) {
            m1[0].data[i] = 0 ;
        }
        return m1;
    }
    
    
    // set data
 
void setMatrixValues_int32(Matrix_int32* m1, FILE* filePointer, int* label, int op) {
    #ifndef MEM_LOAD_MODE
    getData_int32(filePointer, m1[0].rows * m1[0].cols + 1, label, m1[0].data, op);
    #endif
    return;
}
   
void setMatrixValues_int8(Matrix_int8* m1, FILE* filePointer, int* label, int op) {
    #ifndef MEM_LOAD_MODE
    getData_int8(filePointer, m1[0].rows * m1[0].cols + 1 , label, m1[0].data, op);
    #endif
    return;
}

void setMatrixValues_uint8(Matrix_uint8* m1, FILE* filePointer, int* label, int op) {
    #ifndef MEM_LOAD_MODE
    getData_uint8(filePointer, m1[0].rows * m1[0].cols  + 1 , label, m1[0].data, op);
    #else
      int matrix_idx ; // For future tracking , currently not used
      getData_mfds_uint8(filePointer, (m1[0].rows * m1[0].cols)  + 2 , &matrix_idx, label, m1[0].data, op);  // read matrix data from Mannix Format DataSet (mfds) file.
    #endif
    return;
}


void setMatrixSize_int8(Matrix_int8* matrix, int n_rows, int n_cols) {

    matrix->rows = n_rows;
    matrix->cols = n_cols;
}

void setMatrixSize_uint8(Matrix_uint8* matrix, int n_rows, int n_cols) {

    matrix->rows = n_rows;
    matrix->cols = n_cols;
}

void setMatrixSize_int32(Matrix_int32* matrix, int n_rows, int n_cols) {

    matrix->rows = n_rows;
    matrix->cols = n_cols;
}




// ------------------------- matrix oparations -------------------------
//print matrix 
void printMatrix_int8(Matrix_int8* m1) {
    if(m1->rows <= 0 || m1->cols <= 0) {
        printf("Dimension ERRER - non positive hight or width  [%d][%d]\n",m1-> cols, m1->rows);
        exit(-1);
    }
    int i=0;
    while(i<m1[0].rows * m1[0].cols) {
        if (i % m1[0].cols == 0)
            printf(" [");
        printf("%d ", m1[0].data[i++]);
        if (i % m1[0].cols == 0 && i<m1[0].rows * m1[0].cols)
            printf("]\n");
        else if (i % m1[0].cols == 0)
            printf("]");
    }
    // printf("\n row size = %d, col size = %d\n\n", m1[0].rows, m1[0].cols);
}

void printMatrix_uint8(Matrix_uint8* m1) {
    if(m1->rows <= 0 || m1->cols <= 0) {
        printf("Dimension ERRER - non positive hight or width  [%d][%d]\n",m1-> cols, m1->rows);
        exit(-1);
    }
    int i=0;
    while(i<m1[0].rows * m1[0].cols) {
        if (i % m1[0].cols == 0)
            printf(" [");
        printf("%d ", m1[0].data[i++]);
        if (i % m1[0].cols == 0 && i<m1[0].rows * m1[0].cols)
            printf("]\n");
        else if (i % m1[0].cols == 0)
            printf("]");
    }
    // printf("\n row size = %d, col size = %d\n\n", m1[0].rows, m1[0].cols);
}


void printMatrix_int32(Matrix_int32* m1) {
    if(m1->rows <= 0 || m1->cols <= 0) {
        printf("Dimension ERRER - non positive hight or width  [%d][%d]\n",m1-> cols, m1->rows);
        exit(-1);
    }
    int i=0;
    while(i<m1[0].rows * m1[0].cols) {
        if (i % m1[0].cols == 0)
            printf(" [");
        printf("%d ", m1[0].data[i++]);
        if (i % m1[0].cols == 0 && i<m1[0].rows * m1[0].cols)
            printf("]\n");
        else if (i % m1[0].cols == 0)
            printf("]");
    }
    // printf("\n row size = %d, col size = %d\n\n", m1[0].rows, m1[0].cols);
}





#ifdef WINDOWS_MANNIX
//print picture 
void printcolor(Matrix_uint8* m1) {
    if(m1->rows <= 0 || m1->cols <= 0) {
        printf("DImension ERRER - non positive hight or width  [%d][%d]\n",m1-> cols, m1->rows);
        exit(-1);
    }

    int i=0;
    HANDLE hConsole = GetStdHandle(STD_OUTPUT_HANDLE);
    CONSOLE_SCREEN_BUFFER_INFO consoleInfo;
    WORD saved_attributes;

    /* Save current attributes */
    GetConsoleScreenBufferInfo(hConsole, &consoleInfo);
    saved_attributes = consoleInfo.wAttributes;

    while(i<m1[0].rows * m1[0].cols) {

        if(m1->data[i] < 0) {
            printf("Numerical ERROR - non positive data value ");
            #ifdef FLOAT_TYPE
            printf("[%f]\n",m1->data[i]);
            #else
            printf("[%d]\n",m1->data[i]);
            exit(-1);
            #endif
        }

        if (i % m1[0].cols == 0){
            SetConsoleTextAttribute(hConsole, saved_attributes);
            printf("[");
        }

        SetConsoleTextAttribute(hConsole, (WORD)m1[0].data[i++]);
        printf("%c", 32);
        if (i % m1[0].cols == 0 && i<m1[0].rows * m1[0].cols){
            SetConsoleTextAttribute(hConsole, saved_attributes);
            printf("]\n");
        }

        else if (i % m1[0].cols == 0){
            SetConsoleTextAttribute(hConsole, saved_attributes);
            printf("]\n");
        }   
    }
    SetConsoleTextAttribute(hConsole, saved_attributes);
    printf("\n row size = %d, col size = %d\n\n", m1[0].rows, m1[0].cols);
}
#endif



// get matrix
// [optional] states (int state):
// 0 - print matrix only
// 1 - print picture only
// 2 - print matrix and picture
// o.w - dont print
// 
// [optional] label status:
// 0 - with label (for images)
// 1 - without label
//
// return: 0 - success ,-1 - failed
int getMatrix_uint8(Matrix_uint8* m1, FILE * filePointer, int* label, int state, int op){
    if(feof(filePointer))
        return -1;
    // set matrix data
    setMatrixValues_uint8(m1, filePointer, label, op);

    // print matrix options
    if (0 == state || 1 == state || 2 == state) 
        printf("label=%d\n",*label);
    if (0 == state || 2 == state) {
        printMatrix_uint8(m1);
        printf("\n");
    }
    if (1 == state || 2 == state) {
        printcolor(m1);
        printf("\n");
    }
    return 0;
}

int getMatrix_int8(Matrix_int8* m1, FILE * filePointer, int* label, int state, int op){
    if(feof(filePointer))
        return -1;
    // set matrix data
    setMatrixValues_int8(m1, filePointer, label, op);

    // print matrix options
    if (0 == state || 1 == state || 2 == state) 
        printf("label=%d\n",*label);
    if (0 == state || 2 == state) {
        printMatrix_int8(m1);
        printf("\n");
    }
    if (1 == state || 2 == state) {
        //printcolor(m1);
        printf("\n");
    }
    return 0;
}


int getMatrix_int32(Matrix_int32* m1, FILE * filePointer, int* label, int state, int op){
    if(feof(filePointer))
        return -1;
    // set matrix data
    setMatrixValues_int32(m1, filePointer, label, op);

    // print matrix options
    if (0 == state || 1 == state || 2 == state) 
        printf("label=%d\n",*label);
    if (0 == state || 2 == state) {
        printMatrix_int32(m1);
        printf("\n");
    }
    if (1 == state || 2 == state) {
        //printcolor(m1);
        printf("\n");
    }
    return 0;
}


void writeMatrixToCsv_uint8 (Matrix_uint8* m1, char* layer_name) {
    printf(layer_name);
    printf("\n");
    FILE* fptr = fopen(/*"../test_products/test.csv"*/layer_name, "w");
    if(fptr != NULL) 
    for (int i = 0; i < m1->rows; i++) {
        for (int j = 0; j < m1->cols; j++) {
            fprintf(fptr,"%6d",m1->data[i*m1->cols+j]);
        if(m1->rows != j + 1)
            fprintf(fptr,",");            
        }
        fprintf(fptr,"\n");
    }
    else
        printf("Warning - cannot print to csv\n");
    if (fptr != 0) fclose(fptr);
}


void writeMatrixToCsv_int32 (Matrix_int32* m1, char* layer_name) {
    printf(layer_name);
    printf("\n");
    FILE* fptr = fopen(/*"../test_products/test.csv"*/layer_name, "w");
    if(fptr != NULL) 
    for (int i = 0; i < m1->rows; i++) {
        for (int j = 0; j < m1->cols; j++) {
              fprintf(fptr,"%6d",m1->data[i*m1->cols+j]); 
        if(m1->rows != j + 1)
            fprintf(fptr,",");            
        }
        fprintf(fptr,"\n");
    }
    else
        printf("Warning - cannot print to csv\n");
    if (fptr!=0) fclose(fptr);
}


// add matricies
// output stored in the left matrix (m1)
Matrix_int32* addMatrix_int32(Matrix_int32* m1, Matrix_int32* m2) {
    if ((m1->rows != m2->rows) || (m1->cols != m2->cols)) {
        printf("addMatrix_int32 : Dimension ERRER\n");
        printf("m1->rows=%d , m1->cols %d  , m2->rows=%d , m2->cols=%d",m1->rows,m1->cols,m2->rows,m2->cols);
        exit(-1);
    }
    int i=0;
    while(i<m1->size) {
        m1->data[i] += m2->data[i];
        i++;
    }

    return m1;
}

Matrix_int32* addScalarMatrix(Matrix_int32* m1, int num) {
    int i=0;
    while(i<m1->rows * m1->cols) {
        m1->data[i] += num;
        i++;
    }
    return m1;
}

Matrix_int32* mullScalarMatrix(Matrix_int32* m1, int num) {
    int i=0;
    while(i<m1->rows * m1->cols) {
        m1->data[i] *= num;
        i++;
    }
    return m1;
}


// matrix multiplication

// TODO : Need to check properly and efficiently handle transpose. (m1 should be a column matrix)


Matrix_int32* mullMatrix_i32_i8Xui8(Matrix_int8* m1, Matrix_uint8* m2, Matrix_int32* result_matrix, Allocator_int32* al){

   if (m1->cols != m2->rows ) {
        printf("mullMatrix_i32_i8Xui8 Dimension ERROR - Matrices sizes are not match m1->rows=%d , m2->cols=%d\n",m1->rows, m2->cols);
        exit(-1);
    }
    creatMatrix_int32(m1->rows ,m2->cols , result_matrix, al);
    for (int i=0; i< m1->rows; i++) {
        for (int j=0; j < m2->cols; j++) {
            for (int k=0; k < m1->cols; k++) {
                result_matrix->data[(i*(result_matrix->cols))+j] +=  m1->data[(i*(m1->cols))+k] * m2->data[(k*(m2->cols))+j]  ;
            }
        }
    }
    return result_matrix;
}


// transpose
// m - Matrix
Matrix_int8* transpose_int8(Matrix_int8* m) {
    if(m->rows <= 0 || m->cols <= 0) {
        printf("DImension ERRER - non positive hight or width  [%d][%d]\n",m-> cols, m->rows);
        exit(-1);
    }
    for(int i = 0; i < m->rows - 1; i++)
        for(int j = i + 1; j < m->cols; j++) {
            signed char temp = m->data[i*m->cols + j]; 
            m->data[i*m->cols + j] = m->data[j*m->cols + i];
            m->data[j*m->cols + i] = temp;
        }
    return m;
}

// ================= CNN functions ============================

void setBias(Matrix_int32* bias, char* file_path, char* type, int layer, char* w_b) {
#ifndef MEM_LOAD_MODE    
    int label[1];

    FILE* fd = createFdFc(file_path, type, layer, w_b);
    getMatrix_int32(bias, fd, label,-1, 1);
    fclose(fd);
#endif
}


void setWeight(Matrix_int8* weight, char* file_path, char* type, int layer, char* w_b) {
#ifndef MEM_LOAD_MODE
    int label[1];
    FILE* fd = createFdFc(file_path, type, layer, w_b);
    getMatrix_int8(weight, fd, label,-1, 1);
    fclose(fd);
#endif
}


// Hadamard multiplication:
// x - window's starting row 
// y - window's starting column
int hadamardMullMatrix(Matrix_uint8* m1, Matrix_int8* m2, int x, int y) {
    int filter_sum=0;;
    for (int i=0; i < m2->rows; i++) {
        for (int j=0; j < m2->cols; j++) {
            int m1_idx = (i + x) * m1->cols + j + y ;
            int m2_idx = i* m2->cols + j ;
            unsigned char m1_val = m1->data[m1_idx] ;
            signed char m2_val = m2->data[m2_idx];
            int mul_val = m1_val * m2_val ;
            filter_sum +=  mul_val ; 
        }
    }
    return filter_sum;
}



unsigned char getMax(Matrix_uint8* m1, int p_m, int p_n, int x, int y, int stride) {

    unsigned char filter_sum = m1->data[x * stride * m1->cols + y * stride];
    for (int i=0; i < p_m; i++) {
        for (int j=0; j < p_n; j++) {
            unsigned char data_val = m1->data[(i + x * stride) * m1->cols + j + y * stride] ;
            if (filter_sum < data_val) filter_sum = data_val ;
        }
    }
    return filter_sum;
}




// maxpuling 
// p_m - window's hight
// p_n - window's width
Matrix_uint8* matrixMaxPool(Matrix_uint8* m1, Matrix_uint8* m2, int p_m, int p_n, int stride){
    
    int k = 0;

    // set data
    for (int i=0; i < m2->rows; i = i++) {
        for (int j=0; j < m2->cols; j = j++) {
            m2->data[k++] = getMax(m1, p_m, p_n, i, j, stride);
        }
    }
    return m2;
}


// mull and sum:
// multiple window by the filter 
// and return the sum of the window 
Matrix_int32* matrixConvolution(Matrix_uint8* m1, Matrix_int8* m_filter, int bias, Matrix_int32* result_matrix){

    for (int i=0; i < result_matrix->rows ; i++) {
        for (int j=0; j < result_matrix->cols ; j++) {
            result_matrix->data[i*result_matrix->cols + j] = hadamardMullMatrix(m1, m_filter, i, j) + bias;  //TODO ask Udi why I am getting more accurate results without bias                                                                        
        }
    }

    return result_matrix;
}

// add and reLU at the same time so no Matrix_int32 need to be stored for activation
Matrix_uint8* matrixAddNActivate(Matrix_int32* sum_matrix, Matrix_int32* tmp_matrix, Matrix_uint8* result_matrix, int sc) {
    
    int i = 0;
    int scale = (1 << (WB_LOG2_SCALE + sc) ) ; // 'sc' (extra scale) is determined by LOG2_RELU_FACTOR ;

    while(i<result_matrix->size) {
        int conv_data = sum_matrix->data[i] + tmp_matrix->data[i];
        int descaled_data = conv_data / scale ;
        result_matrix->data[i] = (unsigned char) (descaled_data >= MAX_DATA_RANGE) ? MAX_DATA_RANGE : ((descaled_data <= 0) ? 0 : descaled_data) ;
        i++;
    }

    return  result_matrix;
} 



Matrix_uint8 * matrixActivation(Matrix_int32* m1, int sc) { // TODO : VERIFY CORRECT OVERLAY
    

    Matrix_uint8 *m_out = (Matrix_uint8 *) m1 ; // overlay output matrix
    unsigned char * data = (unsigned char *) m1->data ; // output data as uint8 overlay input data int32
    
    int i = 0;
    int scale = (1 << (WB_LOG2_SCALE + sc) ) ; // 'sc' (extra scale) is determined by LOG2_RELU_FACTOR ;
    while(i<m1->size) {
        int descaled_data = m1->data[i] / scale ;
        data[i] = (char) (descaled_data >= MAX_DATA_RANGE) ? MAX_DATA_RANGE : ((descaled_data <= 0) ? 0 : descaled_data) ;
        i++;
    }
    return m_out ;
}

Matrix_int32* matrixFC(Matrix_uint8* input_matrix, Matrix_int8* weight_matrix, Matrix_int32* bias_vector, Matrix_int32* result_matrix, Allocator_int32* al) {

   // Notice : Matrix algebra order is : (weight_matrix * input_matrix) + bias
   // Currently we assume input matrix is a single column. 

    if (input_matrix->cols!=1) {
        printf("matrixFC : Dimension ERROR, currently we restrict input matrix to a single column\n");
        printf("input_matrix->rows=%d , input_matrix->cols=%d\n",input_matrix->rows,input_matrix->cols);
        exit(-1); 
    }    
 

    else if (input_matrix->rows != weight_matrix->cols)  {
        printf("matrixFC : Dimension ERROR :\n");
        printf("input_matrix->rows=%d , weight_matrix->cols=%d\n",input_matrix->rows,weight_matrix->cols);
        exit(-1);
    }
    
   
    mullMatrix_i32_i8Xui8(weight_matrix,input_matrix,result_matrix,al);


    addMatrix_int32(result_matrix, bias_vector);

    return result_matrix;
}


Matrix_uint8* matrixFCNActivate(Matrix_uint8* input_matrix, Matrix_int8* weight_matrix, Matrix_int32* bias_vector, Matrix_uint8* result_matrix, Allocator_int32* al, int sc) {

   // Notice : Matrix algebra order is : (weight_matrix * input_matrix) + bias
   // Currently we assume input matrix is a single column. 
    Matrix_int32 tmp_matrix[1];

    if (input_matrix->cols!=1) {
        printf("matrixFC : Dimension ERROR, currently we restrict input matrix to a single column\n");
        printf("input_matrix->rows=%d , input_matrix->cols=%d\n",input_matrix->rows,input_matrix->cols);
        exit(-1); 
    }    
 

    else if (input_matrix->rows != weight_matrix->cols)  {
        printf("matrixFC : Dimension ERROR :\n");
        printf("input_matrix->rows=%d , weight_matrix->cols=%d\n",input_matrix->rows,weight_matrix->cols);
        exit(-1);
    }

    creatMatrix_uint8(weight_matrix->rows, input_matrix->cols, result_matrix, (Allocator_uint8*) al);     
    creatMatrix_int32(weight_matrix->rows, input_matrix->cols, tmp_matrix, al);     

    mullMatrix_i32_i8Xui8(weight_matrix,input_matrix,tmp_matrix,al);

    matrixAddNActivate(tmp_matrix, bias_vector, result_matrix, sc);

    mannixDataFree_int32(al, tmp_matrix->data, tmp_matrix->size);

    return result_matrix;
}



int maxElement_uint8(Matrix_uint8* result_matrix) {
    int max = result_matrix->data[0];
    int key = 0;
    for(int i = 1; i < result_matrix->size; i++) {
        if (max < result_matrix->data[i]) {
            max = result_matrix->data[i];
            key = i;
        }
    }
    return key;
}

#endif