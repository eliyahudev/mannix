#include "inc.h"

typedef struct Allocator
{
    int index;
    int max_size;
    int* data;
} Allocator;

typedef struct Matrix
{
    int rows;
    int cols;
    int size;
    int* data;
} Matrix;

// memory allocation
Allocator* createAllocator(Allocator* alloc, int* data, int max_size);
int* mannixDataMalloc(Allocator* alloc, int length);

// matrix creation
Matrix* creatMatrix(int rows, int cols, Matrix* m1, Allocator* al);
void setMatrixValues(Matrix* m1, FILE* filePointer, int* label);

// matrix oparations
void printMatrix(Matrix* m1);
void printcolor(Matrix* m1);
int getMatrix(Matrix* m1, FILE * filePointer, int* label, int op);
Matrix* addMatrix(Matrix* m1, Matrix* m2);
Matrix* mullMatrix(Matrix* m1, Matrix* m2, Matrix* result_matrix, Allocator* al);
int hadamardMullMatrix(Matrix* m1, Matrix* m2, Matrix* result_matrix, int x, int y);
Matrix* mns(Matrix* m1, Matrix* m_filter, Matrix* result_matrix, Allocator* al);
int getMax(Matrix* m1, Matrix* result_matrix, int p_m, int p_n, int x, int y, int stride);
Matrix* maxPull(Matrix* m1, Matrix* result_matrix, Allocator* al, int p_m, int p_n, int stride);


// ==================== main ==========================

int main(int argc, char const *argv[]) {
    int N,M;
    if (argc >1)
        N = atoi(argv[1]);
    else
        N = 28;
    if (argc >2)
        M = atoi(argv[2]);
    else
        M = N;
    
    //create memory allocator;
    int data[10000];
    Allocator al[1];
    createAllocator(al, data, 10000);

    // create and get access to matrix via pointer
    Matrix m[1];
    Matrix m2[1];
    Matrix m3[1];
    Matrix m4[1];

    creatMatrix(N ,M , m, al);
    creatMatrix(N ,M , m2, al);
    // create matrix from exel file 
    int label;
    FILE *filePointer;
    filePointer = fopen("source/data_set_256_fasion_emnist.csv", "r");

    getMatrix(m, filePointer, &label, 0);
    getMatrix(m2, filePointer, &label, -1);
    int offset=3;
    // mns(m, m2, m3, al);
    maxPull(m, m3, al, 4, 4, 4);
    printMatrix(m3);
    fclose(filePointer);

    return 0;
}

// ====================== functions ===============================
// ================= memory allocation ============================
Allocator* createAllocator(Allocator* alloc, int* data, int max_size) {
    alloc[0].index = 0;
    alloc[0].max_size = max_size-1;
    alloc[0].data = data;
    return alloc;
}

int* mannixDataMalloc(Allocator* alloc, int length) {
    if (alloc[0].index + length < alloc[0].max_size)
        alloc[0].index += length;
    else {
        printf("ERROR-out of range allocation");
        exit(-1);
    }
    return alloc[0].data + alloc[0].index -length; 
    }

// TODO - MATRIX ALLOCATOR maybe useful

    // ================== matrix functions ========================
    // ------------------matrix creation -------------------------
    // cearte matrix with the value of zero 
    Matrix* creatMatrix(int rows, int cols, Matrix* m1, Allocator* al) {
        m1[0].cols = cols;
        m1[0].rows = rows;
        m1->size = cols * rows;
        m1[0].data = mannixDataMalloc(al, cols * rows);
        for (size_t i = 0; i < rows*cols; i++) {
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


//print matrix 
void printcolor(Matrix* m1) {
    int i=0;
    HANDLE hConsole = GetStdHandle(STD_OUTPUT_HANDLE);
    CONSOLE_SCREEN_BUFFER_INFO consoleInfo;
    WORD saved_attributes;

    /* Save current attributes */
    GetConsoleScreenBufferInfo(hConsole, &consoleInfo);
    saved_attributes = consoleInfo.wAttributes;

    while(i<m1[0].rows * m1[0].cols) {
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


// get the max element from a window
int getMax(Matrix* m1, Matrix* result_matrix, int p_m, int p_n, int x, int y, int stride) {

    int filter_sum = m1->data[x * stride * m1->cols + y * stride];
    // printf("[\n"); // for internal test
    for (int i=0; i < p_m; i++) {
        printf("[");
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

// max pull for NN:
// for an input of size W1xH1 where:
// W1 - is width of the input
// H1 - is height of the input 
// f = filter size
// s - stride
// then Output shape would be W2xH2,Where:
// W2=(W1-f)/s +1
// H2=(H1-f)/s+1
Matrix* maxPull(Matrix* m1, Matrix* result_matrix, Allocator* al, int p_m, int p_n, int stride){

    creatMatrix((m1->rows - p_m) / stride + 1 ,(m1->cols - p_m) / stride + 1, result_matrix, al);
    for (int i=0; i < result_matrix->rows + 1; i = i++) {
        for (int j=0; j < result_matrix->cols + 1; j = j++) {
            result_matrix->data[i*result_matrix->cols + j] = getMax(m1, result_matrix, p_m, p_n, i, j, stride);
        }
    }
    return result_matrix;
}

