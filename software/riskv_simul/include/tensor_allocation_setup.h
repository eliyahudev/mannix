 #ifndef TENSOR_ALLOCATION_SETUP
 #define TENSOR_ALLOCATION_SETUP
    //tensor_allocation_setup 
    int N,M;
    int label;

    if (argc >1)
        N = atoi(argv[1]);
    else
        N = 6;
    if (argc >2)
        M = atoi(argv[2]);
    else
        M = N;

    
    //memory allocated
#ifdef VS_MANNIX
    DATA_TYPE* data = (DATA_TYPE*)malloc(sizeof(DATA_TYPE)* MANNIX_DATA_SIZE);  // we may use float for the first test infirence
    Matrix* alloc_matrix = (Matrix*)malloc(sizeof(DATA_TYPE)* MANNIX_MAT_SIZE);
    Tensor* tens = (Tensor*)malloc(sizeof(Tensor)* MANNIX_TEN_SIZE);
#else
    DATA_TYPE data[MANNIX_DATA_SIZE];  // we may use float for the first test infirence
    Matrix alloc_matrix[MANNIX_MAT_SIZE];
    Tensor tens[MANNIX_TEN_SIZE];
#endif

    //declare allocotors 
    Allocator al[1];
    MatAllocator mat_al[1];
    TensorAllocator tens_alloc[1];

    // allocate memory
    createAllocator(al, data, MANNIX_DATA_SIZE);
    createMatrixAllocator(mat_al, alloc_matrix, MANNIX_MAT_SIZE);
    createTensorAllocator( tens_alloc, tens, MANNIX_TEN_SIZE);
#endif