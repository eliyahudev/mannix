//create memory allocator;
    int data[10000];
    Allocator al[1];
    createAllocator(al, data, 10000);

    // create and get access to matrix via pointer
    Matrix m[1];
    Matrix m2[1];
    Matrix m3[1];
    Matrix m4[1];

    creatMatrix(N ,M , m, al);
    creatMatrix(4 ,4 , m2, al);
    // create matrix from exel file 
    int label;
