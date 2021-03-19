#ifndef MANNIX_LIB
#define MANNIX_LIB


// ================= int allocation ============================
Allocator_int32* createAllocator_int32(Allocator_int32* alloc, int * data, int max_size) {
    alloc[0].index = 0;
    alloc[0].max_size = max_size-1;
    alloc[0].data = data;
    return alloc;
}

Allocator_int8* createAllocator_int8(Allocator_int8* alloc, signed char* data, int max_size) {
    alloc[0].index = 0;
    alloc[0].max_size = max_size-1;
    alloc[0].data = data;
    return alloc;
}

Allocator_uint8* createAllocator_uint8(Allocator_uint8* alloc, unsigned char* data, int max_size) {
    alloc[0].index = 0;
    alloc[0].max_size = max_size-1;
    alloc[0].data = data;
    return alloc;
}

static int data_buf_req_byte_size = 0 ;

int* mannixDataMalloc_int32(Allocator_int32* alloc, int length) {
    
    Allocator_uint8 * byte_alloc = (Allocator_uint8 *) alloc ;
    
    int byte_length = length*4 ;
    if (byte_alloc[0].index + byte_length < byte_alloc[0].max_size)
        byte_alloc[0].index += byte_length;
    else {
        printf("ERROR-out of range allocation");
        exit(-1);
    }
    if (byte_alloc[0].index > data_buf_req_byte_size) {
     printf("model weights/bias allocated data memory %d\n",byte_alloc[0].index) ;
     data_buf_req_byte_size = byte_alloc[0].index ;
    }
    
    return (int *)(byte_alloc[0].data + byte_alloc[0].index - byte_length); 
}
    
 
signed char* mannixDataMalloc_int8(Allocator_int8* alloc, int length) {
    if (alloc[0].index + length < alloc[0].max_size)
        alloc[0].index += length;
    else {
        printf("ERROR-out of range allocation");
        exit(-1);
    }
    printf("model weights/bias allocated data memory %d\n",alloc[0].index) ;
    if (alloc[0].index > data_buf_req_byte_size) {
     printf("model weights/bias allocated data memory %d\n",alloc[0].index) ;
     data_buf_req_byte_size = alloc[0].index ;
    }
    return alloc[0].data + alloc[0].index -length; 
}

char* mannixDataMalloc_uint8(Allocator_uint8* alloc, int length) {
    if (alloc[0].index + length < alloc[0].max_size)
        alloc[0].index += length;
    else {
        printf("ERROR-out of range allocation");
        exit(-1);
    }
    if (alloc[0].index > data_buf_req_byte_size) {
     printf("model weights/bias allocated data memory %d\n",alloc[0].index) ;
     data_buf_req_byte_size = alloc[0].index ;
    }    
    return alloc[0].data + alloc[0].index -length; 
}
 
 

int mannixDataFree_int32(Allocator_int32* alloc, int* data, int length) {
    
    Allocator_uint8 * byte_alloc = (Allocator_uint8 *) alloc ;
    
    int byte_length = length*4 ;
    if ((byte_alloc->data + byte_alloc->index - byte_length) == (unsigned char *)data)
        byte_alloc->index -= byte_length;
    else {
        printf("ERROR- cannot free memory due to incorrect size  [%p][%p]\n",(alloc->data - length),data);
        exit(-1);
    }
    return 0;
}


// ================= Matrix allocation ============================

MatAllocator_int32  * createMatrixAllocator_int32 ( MatAllocator_int32 * mat_alloc, Matrix_int32* matrix, int max_size) {
    mat_alloc->index = 0;
    mat_alloc->max_size = max_size-1;
    mat_alloc->matrix = matrix;
    return mat_alloc;
}

MatAllocator_uint8  * createMatrixAllocator_uint8 ( MatAllocator_uint8 * mat_alloc, Matrix_uint8* matrix, int max_size) {
    mat_alloc->index = 0;
    mat_alloc->max_size = max_size-1;
    mat_alloc->matrix = matrix;
    return mat_alloc;
}



Matrix_int32* mannixMatrixMalloc_int32(MatAllocator_int32* mat_alloc, int length) {
    if (mat_alloc->index + length < mat_alloc->max_size)  mat_alloc->index += length;
    else {
        printf("ERROR-out of range allocation");
        exit(-1);
    }
    return mat_alloc->matrix + mat_alloc->index -length; 
}

Matrix_int8* mannixMatrixMalloc_int8(MatAllocator_int8* mat_alloc, int length) {
    if (mat_alloc->index + length < mat_alloc->max_size)  mat_alloc->index += length;
    else {
        printf("ERROR-out of range allocation");
        exit(-1);
    }
    return mat_alloc->matrix + mat_alloc->index -length; 
}

Matrix_uint8* mannixMatrixMalloc_uint8(MatAllocator_uint8* mat_alloc, int length) {
    if (mat_alloc->index + length < mat_alloc->max_size)  mat_alloc->index += length;
    else {
        printf("ERROR-out of range allocation");
        exit(-1);
    }
    return mat_alloc->matrix + mat_alloc->index - length;
}


// ================= Tensor allocation ============================
TensorAllocator_int32* createTensorAllocator_int32(TensorAllocator_int32* tens_alloc, Tensor_int32* tens, int max_size) {
    tens_alloc->index = 0;
    tens_alloc->max_size = max_size-1;
    tens_alloc->tensor = tens;
    return tens_alloc;
}

TensorAllocator_uint8* createTensorAllocator_uint8(TensorAllocator_uint8* tens_alloc, Tensor_uint8* tens, int max_size) {
    tens_alloc->index = 0;
    tens_alloc->max_size = max_size-1;
    tens_alloc->tensor = tens;
    return tens_alloc;
}



Tensor_int32* mannixTensorMalloc_int32(TensorAllocator_int32* tens_alloc, int length) {
    if (tens_alloc->index + length < tens_alloc->max_size)
        tens_alloc->index += length;
    else {
        printf("ERROR-out of range allocation");
        exit(-1);
    }
    return tens_alloc->tensor + tens_alloc->index -length; 
}



Tensor_uint8* mannixTensorMalloc_uint8(TensorAllocator_uint8* tens_alloc, int length) {
    if (tens_alloc->index + length < tens_alloc->max_size)
        tens_alloc->index += length;
    else {
        printf("ERROR-out of range allocation");
        exit(-1);
    }
    return tens_alloc->tensor + tens_alloc->index -length; 
}


Tensor_int8* mannixTensorMalloc_int8(TensorAllocator_int8* tens_alloc, int length) {
    if (tens_alloc->index + length < tens_alloc->max_size)
        tens_alloc->index += length;
    else {
        printf("ERROR-out of range allocation");
        exit(-1);
    }
    return tens_alloc->tensor + tens_alloc->index -length; 
}

//======================================================================================

// Mannif Format (mfdb , mfds) Access functions

void dump_model_params_mfdb(Allocator_uint8 *alloc, char *dumpFileName) {
    
    FILE* dumpFile = fopen(dumpFileName,"w");

    printf("Dumping model parameters to %s\n",dumpFileName); 
    for (int i=0; i<alloc->index; i++) fprintf(dumpFile,"%02x\n",alloc->data[i]);    
    fclose(dumpFile) ;
    printf("\n\nDONE Dumping , exiting\n\n");
    exit(0);
}


void load_model_params_mfdb(Allocator_uint8 *alloc, char *dumpFileName) {
    
    FILE* dumpFile = fopen(dumpFileName,"r");

    printf("Loading model parameters from %s\n",dumpFileName); 
    for (int i=0; i<alloc->index; i++) {
        unsigned int val ;
        fscanf(dumpFile,"%x",&val);
        alloc->data[i] = (unsigned char)val ;
    }        
    fclose(dumpFile) ;
    printf("\n\nDONE Loading, proceeding.\n\n");
}

void getData_mfds_uint8(FILE* mfds_filePointer, int num_data_to_read, int* matrix_idx_ptr , int* label_ptr, unsigned char* matrix_flat_vec, int op) {
     fscanf(mfds_filePointer,"%x",matrix_idx_ptr);
     fscanf(mfds_filePointer,"%x",label_ptr); 
    for (int i=0; i<num_data_to_read-2; i++) {  // already taken 2 items
        unsigned int val ;
        fscanf(mfds_filePointer,"%x",&val);
        matrix_flat_vec[i] = (unsigned char)val ;
    }             
}


//=======================================================================================

#endif // MANNIX_LIB
