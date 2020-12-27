#include "stdio.h"
#include <stdlib.h>
#include "read_csv.h"
typedef struct Matrix
{
    int rows;
    int cols;
    int** data;
} Matrix;


// cearte matrix with the value of zero 
Matrix* creatMatrix(int rows, int cols) {
    Matrix* m1 = (Matrix*)malloc(sizeof(Matrix));
    m1->cols = cols;
    m1->rows = rows;
    m1->data = (int**)malloc(sizeof(int)*rows);
    for (size_t i = 0; i < rows; i++)
    {
        m1->data[i] = (int*)malloc(sizeof(int)*cols);
        for (size_t j = 0; j < cols; j++)
        {
            m1->data[i][j] = 0;
        }
    }
    return m1;
}

//print matrix 
void printMatrix(Matrix* m1) {

    for (size_t i = 0; i < m1->rows; i++)
    {
        printf("[ ");
        for (size_t j = 0; j < m1->cols; j++)
        {
            printf("%d ", m1->data[i][j]);
        }
        printf("]\n");
    }
    printf("\n row size = %d, col size = %d\n\n", m1->rows, m1->cols);
}

// free alocated matrix
void deleteMatrix(Matrix* m1) {
    for (size_t i = 0; i < m1->rows; i++)
    {
            free(m1->data[i]);
    }
    free(m1->data);
    free(m1);   
    printf ("memory is free\n");
}

void setMatrixValues(Matrix* m1, char* path) {
    int *x = getData(path, m1->rows*m1->cols);
    free(x);
    printf("done\n");
    return;

}
/*
void addMatrix(Matrix* m1, Matrix* m2) {
    if (m1->rows != m2->rows || m1->cols != m2->cols) {
        printf("DImension ERRER - Matricies sizes are not equal");
        return;
    }
    for (int i=0; i<m1->rows; i++) {
        for (int j=0; j<m1->cols; j++) { 
            m1->data[i][j] += m2->data[i][j]; 
        }
    }
}

void subMatrix(Matrix* m1, Matrix* m2) {
    if (m1->rows != m2->rows || m1->cols != m2->cols) {
        printf("DImension ERRER - Matricies sizes are not equal");
        return;
    }
    for (int i=0; i<m1->rows; i++) {
        for (int j=0; j<m1->cols; j++) { 
            m1->data[i][j] -= m2->data[i][j]; 
        }
    }
}

void mulMatrix(Matrix* m1, Matrix* m2) {
    if (m1->cols != m2->rows) {
        printf("DImension ERRER - Matricies sizes are not equal");
        return;
    }
    Matrix* m3 = creatMatrix(m1->rows, m2->cols);
    for (int i=0; i<m1->rows; i++) {
        for (int j=0; j<m2->cols; j++) {
                for (int k=0; k<m1->cols; k++) 
                    m3->data[i][j] += m1->data[i][k] * m2->data[k][j]; 
        }
    }
    deleteMatrix(m1);
    m1 = m3;
}

void asignMatrix(Matrix* m1, Matrix* m2) {
    if (m1->rows != m2->rows || m1->cols != m2->cols) {
        printf("DImension ERRER - Matricies sizes are not equal");
        return;
    }
    for (int i=0; i<m1->rows; i++) {
        for (int j=0; j<m1->cols; j++) {
            m1->data[i][j] = m2->data[i][j];
        }
    }
}

void AsignValeus2Matrix(Matrix* m1, int rows, int cols, int value) {
    m1->data[rows][cols] = value;
}
*/
int main() {

    Matrix* m2 = creatMatrix(4,2);
    Matrix* m1 = creatMatrix(2,4);
  //  mulMatrix(m2,m1);
    printMatrix(m2);
    printMatrix(m1);
    setMatrixValues(m1, "test.csv");
    deleteMatrix(m1);
    deleteMatrix(m2);
    return 0;
}
