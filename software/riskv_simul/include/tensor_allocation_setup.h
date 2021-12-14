 #ifndef TENSOR_ALLOCATION_SETUP
 #define TENSOR_ALLOCATION_SETUP
    //tensor_allocation_setup 
    // int N,M;
    //int label;

    // if (argc >1)
    //     N = atoi(argv[1]);
    // else
    //     N = 6;
    // if (argc >2)
    //     M = atoi(argv[2]);
    // else
    //     M = N;
    
    //memory allocated

    char data[MANNIX_DATA_SIZE];  // we may use float for the first test inference
    char alloc_matrix[MANNIX_MAT_SIZE*sizeof(char)];
    char tens[MANNIX_TEN_SIZE*sizeof(char)];

    //declare allocotors 
    Allocator_uint8 al[1];
    MatAllocator_uint8 mat_al[1];
    TensorAllocator_uint8 tens_alloc[1];

    // allocate memory  - at byte granularity -- Works also for VS
    createAllocator_uint8(al, data, MANNIX_DATA_SIZE);
    createMatrixAllocator_uint8(mat_al, (Matrix_uint8*) alloc_matrix, MANNIX_MAT_SIZE);
    createTensorAllocator_uint8( tens_alloc, (Tensor_uint8*) tens, MANNIX_TEN_SIZE);
    
    
    
#endif