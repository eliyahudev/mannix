#include "stdio.h"
#include <stdlib.h>
#include "read_csv.h"
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
    Matrix m[2];
    Matrix* matrix_ptr = creatMatrix(N ,M , m, al);

    // create matrix from exel file 
    int label;
    FILE *filePointer;
    filePointer = fopen("r.csv", "r");
    while (!feof(filePointer))
        setMatrixValues(matrix_ptr, filePointer, &label);
    printf("label=%d\n",label);
    printMatrix(matrix_ptr);

    //close file
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
    return alloc[0].data; 
}

// ================== matrix functions ========================
// ------------------matrix creation -------------------------
// cearte matrix with the value of zero 
Matrix* creatMatrix(int rows, int cols, Matrix* m1, Allocator* al) {
    m1[0].cols = cols;
    m1[0].rows = rows;
    m1[0].data = mannixDataMalloc(al, cols * rows);
    for (size_t i = 0; i < rows*cols; i++) {
        m1[0].data[i] = 0;
    }
    return m1;
}

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
