#ifndef MANNIX_MATRIX
#define MANNIX_MATRIX

typedef struct Matrix
{
    int rows;
    int cols;
    int size;
    int* data;
} Matrix;


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
    void setMatrixValues(Matrix* m1, FILE* filePointer, int* label) {
        getData(filePointer, m1[0].rows * m1[0].cols + 1, label, m1[0].data);
    return;
}

// ------------------------- matrix oparations -------------------------
//print matrix 
void printMatrix(Matrix* m1) {
    if(m1->rows <= 0 || m1->cols <= 0) {
        printf("DImension ERRER - non positive hight or width  [%d][%d]\n",m1-> cols, m1->rows);
        exit(-1);
    }
    int i=0;
    while(i<m1[0].rows * m1[0].cols) {
        if (i % m1[0].cols == 0)
            printf("[");
        printf("%d ", m1[0].data[i++]);
        if (i % m1[0].cols == 0 && i<m1[0].rows * m1[0].cols)
            printf("]\n");
        else if (i % m1[0].cols == 0)
            printf("]\n");
    }
    printf("\n row size = %d, col size = %d\n\n", m1[0].rows, m1[0].cols);
}


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

// get matrix
// 0 - print matrix only
// 1 - print picture only
// 2 - print matrix and picture
// o.w - dont print
int getMatrix(Matrix* m1, FILE * filePointer, int* label, int op){
    if(feof(filePointer))
        return -1;
    // set matrix data
    setMatrixValues(m1, filePointer, label);
    // print matrix options
    if (0 == op || 1 == op || 2 == op) 
        printf("label=%d\n",*label);
    if (0 == op || 2 == op)
        printMatrix(m1);
    if (1 == op || 2 == op)
        printcolor(m1);
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
    while(i<m1->rows * m1->cols) {
        m1->data[i] += m2->data[i];
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

// ================= CNN functions ============================

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
    // printf("[\n"); // for internal test
    for (int i=0; i < p_m; i++) {
        // printf("[");
        for (int j=0; j < p_n; j++) {
            if (filter_sum < m1->data[(i + x * stride) * m1->cols + j + y * stride])
                filter_sum = m1->data[(i + x * stride) * m1->cols + j + y * stride]; //[i][j]
            // printf(" %d ; ", m1->data[(i + x * stride) * m1->cols + j + y * stride]);
        }
        // printf("]\n");
    }
    // printf("]\n");
    // printf("------------max = %d ---------- [%d][%d]\n\n", filter_sum ,x, y);
    return filter_sum;
}


#endif