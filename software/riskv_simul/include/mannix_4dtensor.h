// ============================== tensor4d ==============================
// ============================== SETUP ==============================

void create4DTensor_uint8(Tensor4D_uint8* tens_4d, int rows, int cols, int depth, int dim, Allocator_uint8* al, MatAllocator_uint8* mat_alloc, TensorAllocator_uint8* tens_alloc) {
    tens_4d->rows = rows;
    tens_4d->cols = cols;
    tens_4d->depth = depth;
    tens_4d->dim = dim;
    tens_4d->tensor = mannixTensorMalloc_uint8(tens_alloc, dim);

    for(int i = 0; i < tens_4d->dim; i++)
        createTensor_uint8(rows, cols, depth, &tens_4d->tensor[i], al, mat_alloc);
}


void create4DTensor_int8(Tensor4D_int8* tens_4d, int rows, int cols, int depth, int dim, Allocator_int8* al, MatAllocator_int8* mat_alloc, TensorAllocator_int8* tens_alloc) {
    tens_4d->rows = rows;
    tens_4d->cols = cols;
    tens_4d->depth = depth;
    tens_4d->dim = dim;
    tens_4d->tensor = mannixTensorMalloc_int8(tens_alloc, dim);

    for(int i = 0; i < tens_4d->dim; i++)
        createTensor_int8(rows, cols, depth, &tens_4d->tensor[i], al, mat_alloc);
} 


void create4DTensor_int32(Tensor4D_int32* tens_4d, int rows, int cols, int depth, int dim, Allocator_int32* al, MatAllocator_int32* mat_alloc, TensorAllocator_int32* tens_alloc) {
    tens_4d->rows = rows;
    tens_4d->cols = cols;
    tens_4d->depth = depth;
    tens_4d->dim = dim;
    tens_4d->tensor = mannixTensorMalloc_int32(tens_alloc, dim);

    for(int i = 0; i < tens_4d->dim; i++)
        createTensor_int32(rows, cols, depth, &tens_4d->tensor[i], al, mat_alloc);
}


void setFilter(Tensor4D_int8* tens_4d, char* path, int layer) {

#ifndef MEM_LOAD_MODE
    int label[1];
    FILE* fd;

    // set matricies
    for(int i = 0; i < tens_4d->dim; i++)
        for(int j = 0; j < tens_4d->depth; j++) {
            fd = createFilter(path, layer, i, j);  // get file descriptors for csv conv files
            getMatrix_int8(&tens_4d->tensor[i].matrix[j], fd, label,-1, 1);
            fclose(fd);
        }
#endif

}



int setImage(Tensor4D_uint8* tens_4d, FILE* fd) {

    int label;

    // set matricies
    for(int i = 0; i < tens_4d->dim; i++)
        for(int j = 0; j < tens_4d->depth; j++) {
#ifdef TEST
            getMatrix_uint8(&tens_4d->tensor[i].matrix[j], fd, &label, 1, 0);
#else                                                              
    #ifdef CMP_TEST                                              
            getMatrix_uint8(&tens_4d->tensor[i].matrix[j], fd, &label, 1, 1);
    #else                                                        
            getMatrix_uint8(&tens_4d->tensor[i].matrix[j], fd, &label, -1, 0);
    #endif
#endif
        }
    return label;
}

// ============================== Auxiliary functions ==============================

void print4DTensor_uint8(Tensor4D_uint8* tens_4d) {

    printf("tensor{\n");    
    for(int i = 0; i < tens_4d->dim; i++) {
        printf("\n[");
        printTensor_uint8(&tens_4d->tensor[i]);
        printf(" ]\n");
    }
    printf("}\n");
    printf("rows size: %d columns size: %d depth size: %d dim: %d \n\n",tens_4d->rows,tens_4d->cols,tens_4d->depth,tens_4d->dim);

}


void writeTensor4DToCsv_uint8 (Tensor4D_uint8* tens_4d, char* file_path, char* layer_name) {
    
    char path[60];
    char cast_int[3]; // todo - add "warning this function hendle up to 3 digit layer"  
    printf("writing results to:\n");

    for (int i = 0; i < tens_4d->dim; i++) {
        strcpy(path, file_path);
        strcat(path, layer_name);
        strcat(path, "_");
        itoa(i, cast_int, 10);
        strcat(path, cast_int);
        writeTensorToCsv_uint8 (&tens_4d->tensor[i], path) ;
    }
}

void writeTensor4DToCsv_int32 (Tensor4D_int32* tens_4d, char* file_path, char* layer_name) {
    
    char path[60];
    char cast_int[3]; // todo - add "warning this function hendle up to 3 digit layer"  
    printf("writing results to:\n");

    for (int i = 0; i < tens_4d->dim; i++) {
        strcpy(path, file_path);
        strcat(path, layer_name);
        strcat(path, "_");
        itoa(i, cast_int, 10);
        strcat(path, cast_int);
        writeTensorToCsv_int32 (&tens_4d->tensor[i], path) ;
    }
}



// ============================== NN functions ==============================

// convert matrix to vector
void tensor4Dflatten(Tensor4D_uint8* tens_4d) {
    
    tens_4d->rows = tens_4d->rows * tens_4d->cols * tens_4d->depth * tens_4d->dim;
    tens_4d->cols = 1;
    tens_4d->depth = 1;
    tens_4d->dim = 1;
    tensorFlatten(tens_4d->tensor, tens_4d->rows);
}


Tensor4D_int32* tensor4DConvolution(Tensor4D_uint8* tens, Tensor4D_int8* filter, Matrix_int32* bias, Tensor4D_int32* result_4D_tensor, 
                                    Allocator_int32* al, MatAllocator_int32* mat_alloc, TensorAllocator_int32* tens_alloc) 
{
    create4DTensor_int32(result_4D_tensor, tens->rows - filter->rows + 1, tens->cols - filter->cols + 1, filter->dim, 1, al, mat_alloc, tens_alloc);
    for (int i = 0; i < filter->dim; i++) {
        tensorConvolution(&tens->tensor[0], &filter->tensor[i], bias->data[i], &result_4D_tensor->tensor->matrix[i], al, mat_alloc);
    }

    return result_4D_tensor;
}



// new functions replace convolution and activation with a function
// Eliminates the need to maintain int32 tensor
Tensor4D_uint8* tensor4DConvNActivate(Tensor4D_uint8* tens, Tensor4D_int8* filter, Matrix_int32* bias, Tensor4D_uint8* result_4D_tensor, 
                                    Allocator_int32* al, MatAllocator_int32* mat_alloc, TensorAllocator_int32* tens_alloc, int sc) 
{
    create4DTensor_uint8(result_4D_tensor, tens->rows - filter->rows + 1, tens->cols - filter->cols + 1, filter->dim, 1, (Allocator_uint8*) al, (MatAllocator_uint8*) mat_alloc, (TensorAllocator_uint8*) tens_alloc);

    for (int i = 0; i < filter->dim; i++) {
        tensorConvNActivate(&tens->tensor[0], &filter->tensor[i], bias->data[i], &result_4D_tensor->tensor->matrix[i], al, mat_alloc, sc);
    }

    return result_4D_tensor;
}


Tensor4D_uint8* tensor4DActivation(Tensor4D_int32* tens, int sc) {
    
    Tensor4D_uint8 * t_out = (Tensor4D_uint8 *) tens ; // output data as uint8 overlay input data int32
    
    for (int i = 0; i < tens->dim; i++) {
        tensorActivation(&tens->tensor[i], sc);
    }
    return t_out ;
}


Tensor4D_uint8* tensor4DMaxPool(Tensor4D_uint8* tens_4d, Tensor4D_uint8* tens_4d_result, int p_m, int p_n, int stride, Allocator_uint8* al, MatAllocator_uint8* mat_alloc, TensorAllocator_uint8* tens_alloc) {
    
    int new_rows = (tens_4d->rows - p_m) / stride + 1;
    int new_cols = (tens_4d->cols - p_m) / stride + 1;

    create4DTensor_uint8(tens_4d_result, new_rows, new_cols, tens_4d->depth, tens_4d->dim, al, mat_alloc, tens_alloc);

    for (int i = 0; i < tens_4d->dim; i++) {
        tensorMaxPool_uint8(&tens_4d->tensor[i], &tens_4d_result->tensor[i], p_m, p_n, stride);
    }

    return tens_4d_result;
}

