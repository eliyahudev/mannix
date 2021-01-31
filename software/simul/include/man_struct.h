#ifndef MAN_STRUCT
#define MAN_STRUCT

typedef struct Matrix
{
    int rows;
    int cols;
    int size;
    int* data;
} Matrix;



typedef struct Tensor
{
    int rows;
    int cols;
    int depth;
    Matrix* matrix;

} Tensor;

typedef struct Tensor4D
{
    int rows;
    int cols;
    int depth;
    int dim;
    Tensor* tensor;
} Tensor4D;

typedef struct Allocator
{
    int index;
    int max_size;
    int* data;
} Allocator;


typedef struct MatAllocator
{
    int index;
    int max_size;
    Matrix* matrix;
} MatAllocator;

typedef struct TensorAllocator
{
    int index;
    int max_size;
    Tensor* tensor;
} TensorAllocator;

#endif