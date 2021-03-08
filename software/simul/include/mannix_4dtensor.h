// ============================== tensor4d ==============================
// ============================== SETUP ==============================
void create4DTensor(Tensor4D* tens_4d, int rows, int cols, int depth, int dim, Allocator* al, MatAllocator* mat_alloc, TensorAllocator* tens_alloc) {
    tens_4d->rows = rows;
    tens_4d->cols = cols;
    tens_4d->depth = depth;
    tens_4d->dim = dim;
    tens_4d->tensor = mannixTensorMalloc(tens_alloc, dim);

    for(int i = 0; i < tens_4d->dim; i++)
        createTensor(rows, cols, depth, &tens_4d->tensor[i], al, mat_alloc);
}


void setFilter(Tensor4D* tens_4d, char* path, int layer) {

    int label[1];
    FILE* fd;

    // set matricies
    for(int i = 0; i < tens_4d->dim; i++)
        for(int j = 0; j < tens_4d->depth; j++) {
            fd = createFilter(path, layer, i, j);  // get file descriptors for csv conv files
            getMatrix(&tens_4d->tensor[i].matrix[j], fd, label,-1, 1);
            fclose(fd);
        }
}

int setImage(Tensor4D* tens_4d, FILE* fd) {

    int label[1];

    // set matricies
    for(int i = 0; i < tens_4d->dim; i++)
        for(int j = 0; j < tens_4d->depth; j++) {
#ifdef TEST
            getMatrix(&tens_4d->tensor[i].matrix[j], fd, label, 1, 0);
#else
            getMatrix(&tens_4d->tensor[i].matrix[j], fd, label, -1, 0);
#endif
        }
    return label[0];
}

// ============================== Auxiliary functions ==============================

void print4DTensor(Tensor4D* tens_4d) {

    printf("tensor{\n");    
    for(int i = 0; i < tens_4d->dim; i++) {
        printf("\n[");
        printTensor(&tens_4d->tensor[i]);
        printf(" ]\n");
    }
    printf("}\n");
    printf("rows size: %d columns size: %d depth size: %d dim: %d \n\n",tens_4d->rows,tens_4d->cols,tens_4d->depth,tens_4d->dim);

}

// ============================== NN functions ==============================

// convert matrix to vector
void tensor4Dflatten(Tensor4D* tens_4d) {
    
    tens_4d->rows = tens_4d->rows * tens_4d->cols * tens_4d->depth * tens_4d->dim;
    tens_4d->cols = 1;
    tens_4d->depth = 1;
    tens_4d->dim = 1;
    tensorFlatten(tens_4d->tensor, tens_4d->rows);
}


Tensor4D* tensor4DConvolution(Tensor4D* tens, Tensor4D* filter, Matrix* bias, Tensor4D* result_4D_tensor, Allocator* al, MatAllocator* mat_alloc, 
                            TensorAllocator* tens_alloc) {
    create4DTensor(result_4D_tensor, tens->rows - filter->rows + 1, tens->cols - filter->cols + 1, filter->dim, 1, al, mat_alloc, tens_alloc);
    for (size_t i = 0; i < filter->dim; i++) {
        tensorConvolution(&tens->tensor[0], &filter->tensor[i], bias->data[i], &result_4D_tensor->tensor->matrix[i], al, mat_alloc);
    }

    return result_4D_tensor;
}

Tensor4D* tensor4DActivation(Tensor4D* tens) {
    for (size_t i = 0; i < tens->dim; i++) {
        tensorActivation(&tens->tensor[i]);
    }
    return tens;
}


Tensor4D* tensor4DMaxPool(Tensor4D* tens_4d,int p_m, int p_n, int stride) {
    
    int new_rows = (tens_4d->rows - p_m) / stride + 1;
    int new_cols = (tens_4d->cols - p_m) / stride + 1;

    for (size_t i = 0; i < tens_4d->dim; i++) {
        tensorMaxPool(&tens_4d->tensor[i], p_m, p_n, stride);
    }
    tens_4d->rows = new_rows;
    tens_4d->cols = new_cols;
    return tens_4d;
}


Matrix* tesor4DFC(Tensor4D* tens_4d, Matrix* weight_matrix, Matrix* bias_vector, Matrix* result_matrix, Allocator* al) {
    
    tensor4Dflatten(tens_4d);
    tesorFC(tens_4d->tensor, weight_matrix, bias_vector, result_matrix, al);
    return result_matrix;
}
