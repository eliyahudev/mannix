#ifndef MANNIX_MATRIX
#define MANNIX_MATRIX




// ================== matrix functions ========================
    // ------------------matrix creation -------------------------
    // cearte matrix with the value of zero 
Matrix* creatMatrix(int rows, int cols, Matrix* m1, Allocator* al) {
        m1[0].cols = cols;
        m1[0].rows = rows;
        m1->size = cols * rows;
        m1[0].data = mannixDataMalloc(al, cols * rows);
        for (size_t i = 0; i < m1->size; i++) {
            m1[0].data[i] = 0;
        }
        return m1;
    }
    // set data
void setMatrixValues(Matrix* m1, FILE* filePointer, int* label, int op) {
        getData(filePointer, m1[0].rows * m1[0].cols + 1, label, m1[0].data, op);
    return;
}

// void setWeightsMatrix(Tensor4D* tens_4d, char* path, int layer) {

// }


void setMatrixSize(Matrix* matrix, int n_rows, int n_cols) {

    matrix->rows = n_rows;
    matrix->cols = n_cols;
}


// ------------------------- matrix oparations -------------------------
//print matrix 
void printMatrix(Matrix* m1) {
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
void printcolor(Matrix* m1) {
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
            printf("Numerical ERROR - non positive data value [%d]\n",m1->data[i]);
            exit(-1);
        }

        if (i % m1[0].cols == 0){
            SetConsoleTextAttribute(hConsole, saved_attributes);
            printf("[");
        }

        SetConsoleTextAttribute(hConsole, m1[0].data[i++]);
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
int getMatrix(Matrix* m1, FILE * filePointer, int* label, int state, int op){
    if(feof(filePointer))
        return -1;
    // set matrix data
    setMatrixValues(m1, filePointer, label, op);

    // print matrix options
    if (0 == state || 1 == state || 2 == state) 
        printf("label=%d\n",*label);
    if (0 == state || 2 == state) {
        printMatrix(m1);
        printf("\n");
    }
    if (1 == state || 2 == state) {
        printcolor(m1);
        printf("\n");
    }
    return 0;
}


// add matricies
// output stored in the left matrix (m1)
Matrix* addMatrix(Matrix* m1, Matrix* m2) {
    if (m1->rows != m2->rows || m1->cols != m2->cols) {
        printf("DImension ERRER - Matricies sizes are not equal\n");
        exit(-1);
    }
    int i=0;
    while(i<m1->size) {
        int y = m2->data[i];
        m1->data[i] += m2->data[i];
        int x = m1->data[i];
        i++;
    }

    return m1;
}

Matrix* addScalarMatrix(Matrix* m1, int num) {
    int i=0;
    while(i<m1->rows * m1->cols) {
        m1->data[i] += num;
        i++;
    }
    return m1;
}

Matrix* mullScalarMatrix(Matrix* m1, int num) {
    int i=0;
    while(i<m1->rows * m1->cols) {
        m1->data[i] *= num;
        i++;
    }
    return m1;
}


// matrix multipication
// 
Matrix* mullMatrix(Matrix* m1, Matrix* m2, Matrix* result_matrix, Allocator* al){
    if (m1-> cols != m2->rows ) {
        printf("DImension ERRER - Matricies sizes are not match [%d][%d]\n",m1-> cols, m2->rows);
        exit(-1);
    }
    creatMatrix(m1-> rows ,m2->cols , result_matrix, al);
    for (int i=0; i< m1-> rows; i++) {
        for (int j=0; j < m2->cols; j++) {
            for (int k=0; k < m1->cols; k++) {
                result_matrix->data[i*result_matrix->cols + j] +=  m1->data[i*m1->cols+k] * m2->data[k*m2->cols+j];
            }
        }
    }
    return result_matrix;
}

// transpose
// m - Matrix
Matrix* transpose(Matrix* m) {
    if(m->rows <= 0 || m->cols <= 0) {
        printf("DImension ERRER - non positive hight or width  [%d][%d]\n",m-> cols, m->rows);
        exit(-1);
    }
    for(int i = 0; i < m->rows - 1; i++)
        for(int j = i + 1; j < m->cols; j++) {
            int temp = m->data[i*m->cols + j]; 
            m->data[i*m->cols + j] = m->data[j*m->cols + i];
            m->data[j*m->cols + i] = temp;
        }
    return m;
}

// ================= CNN functions ============================

void setBias(Matrix* bias, char* file_path, char* type, int layer, char* w_b) {
    int label[1];
    FILE* fd = createFdFc(file_path, type, layer, w_b);
    getMatrix(bias, fd, label,-1, 1);
    fclose(fd);
}


void setWeight(Matrix* bias, char* file_path, char* type, int layer, char* w_b) {
    int label[1];
    FILE* fd = createFdFc(file_path, type, layer, w_b);
    getMatrix(bias, fd, label,-1, 1);
    fclose(fd);
}


// hadamard multipication:
// x - window's starting row 
// y - window's starting column
int hadamardMullMatrix(Matrix* m1, Matrix* m2, Matrix* result_matrix, int x, int y) {
    
    int filter_sum=0;;
    for (int i=0; i < m2->rows; i++) {
        for (int j=0; j < m2->cols; j++) {
            filter_sum += m1->data[(i + x) * m1->cols + j + y] * m2->data[i* m2->cols + j];
        }
    }
    return filter_sum;
}

int getMax(Matrix* m1, int p_m, int p_n, int x, int y, int stride) {

    int filter_sum = m1->data[x * stride * m1->cols + y * stride];
    for (int i=0; i < p_m; i++) {
        for (int j=0; j < p_n; j++) {
            if (filter_sum < m1->data[(i + x * stride) * m1->cols + j + y * stride])
                filter_sum = m1->data[(i + x * stride) * m1->cols + j + y * stride];
        }
    }
    return filter_sum;
}


// maxpuling 
// p_m - window's hight
// p_n - window's width
Matrix* matrixMaxPool(Matrix* m1, int p_m, int p_n, int stride){
    
    //set filter's window movment
    int new_rows = (m1->rows - p_m) / stride + 1;
    int new_cols = (m1->cols - p_m) / stride + 1;
    int k = 0;
    // set data
    for (int i=0; i < new_rows; i = i++) {
        for (int j=0; j < new_cols; j = j++) {
            m1->data[k++] = getMax(m1, p_m, p_n, i, j, stride);
        }
    }
    // set dimension
    m1->rows = new_rows;
    m1->cols = new_cols;

    return m1;
}


// mull and sum:
// multiple window by the filter 
// and return the sum of the window 
Matrix* matrixConvolution(Matrix* m1, Matrix* m_filter, int bias, Matrix* result_matrix){

    for (int i=0; i < result_matrix->rows ; i++) {
        for (int j=0; j < result_matrix->cols ; j++) {
            result_matrix->data[i*result_matrix->cols + j] = hadamardMullMatrix(m1, m_filter, result_matrix, i, j) + bias;
        }
    }

    return result_matrix;
}


Matrix* matrixActivation(Matrix* m1) {
    int i = 0;
    while(i<m1->size) {
        m1->data[i] = (m1->data[i] >= MAX_FINAL_VAL) ? MAX_FINAL_VAL : ((m1->data[i] <= 0) ? 0 : m1->data[i]) ; // saturate, Scale back to 8-bit
        m1->data[i] = m1->data[i]>>NUM_FINAL_DESCALE_BITS ; // val/FINAL_SCALE ;
        i++;
    }
    return m1;
}


Matrix* matrixFC(Matrix* input_matrix, Matrix* weight_matrix, Matrix* bias_vector, Matrix* result_matrix, Allocator* al) {
    
    mullMatrix(weight_matrix, input_matrix, result_matrix,al);
    addMatrix(result_matrix, bias_vector);

    return result_matrix;
}
#endif