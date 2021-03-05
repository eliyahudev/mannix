#ifndef MANNIX_LIB
#define MANNIX_LIB


// ================= int allocation ============================
Allocator* createAllocator(Allocator* alloc, DATA_TYPE* data, int max_size) {
    alloc[0].index = 0;
    alloc[0].max_size = max_size-1;
    alloc[0].data = data;
    return alloc;
}

DATA_TYPE* mannixDataMalloc(Allocator* alloc, int length) {
    if (alloc[0].index + length < alloc[0].max_size)
        alloc[0].index += length;
    else {
        printf("ERROR-out of range allocation");
        exit(-1);
    }

    return alloc[0].data + alloc[0].index -length; 
    }

int mannixDataFree(Allocator* alloc, DATA_TYPE* data, int length) {
    if (alloc->data + alloc->index - length == data)
        alloc->index -= length;
    else {
        printf("ERROR- cannot free memory due to incorrect size  [%p][%p]\n",(alloc->data - length),data);
        exit(-1);
    }
    return 0;
}

// ================= Matrix allocation ============================
MatAllocator* createMatrixAllocator(MatAllocator* mat_alloc, Matrix* matrix, int max_size) {
    mat_alloc->index = 0;
    mat_alloc->max_size = max_size-1;
    mat_alloc->matrix = matrix;
    return mat_alloc;
}

Matrix* mannixMatrixMalloc(MatAllocator* mat_alloc, int length) {
    if (mat_alloc->index + length < mat_alloc->max_size)
        mat_alloc->index += length;
    else {
        printf("ERROR-out of range allocation");
        exit(-1);
    }
    return mat_alloc->matrix + mat_alloc->index -length; 
    }


// ================= Tensor allocation ============================
TensorAllocator* createTensorAllocator(TensorAllocator* tens_alloc, Tensor* tens, int max_size) {
    tens_alloc->index = 0;
    tens_alloc->max_size = max_size-1;
    tens_alloc->tensor = tens;
    return tens_alloc;
}

Tensor* mannixTensorMalloc(TensorAllocator* tens_alloc, int length) {
    if (tens_alloc->index + length < tens_alloc->max_size)
        tens_alloc->index += length;
    else {
        printf("ERROR-out of range allocation");
        exit(-1);
    }
    return tens_alloc->tensor + tens_alloc->index -length; 
    }

#endif // MANNIX_LIB
