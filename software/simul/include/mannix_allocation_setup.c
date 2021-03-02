    int N,M,D;
    int label;

    if (argc >1)
        N = atoi(argv[1]);
    else
        N = 28;
    if (argc >2)
        M = atoi(argv[2]);
    else
        M = N;
    if(argc > 3)
        D = atoi(argv[3]);
    else
        D = 1;

    //memory allocated
    int data[500000];
    Matrix alloc_matrix[100];
    
    //declare allocotors 
    Allocator al[1];
    MatAllocator mat_al[1];

    // allocate memory
    createAllocator(al, data, 40000);
    createMatrixAllocator(mat_al, alloc_matrix, 100);