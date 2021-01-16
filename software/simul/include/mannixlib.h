#ifndef MANNIX_LIB
#define MANNIX_LIB

typedef struct Allocator
{
    int index;
    int max_size;
    int* data;
} Allocator;

// ================= memory allocation ============================
Allocator* createAllocator(Allocator* alloc, int* data, int max_size) {
    alloc[0].index = 0;
    alloc[0].max_size = max_size-1;
    alloc[0].data = data;
    return alloc;
}

int* mannixDataMalloc(Allocator* alloc, int length) {
    if (alloc[0].index + length < alloc[0].max_size)
        alloc[0].index += length;
    else {
        printf("ERROR-out of range allocation");
        exit(-1);
    }
    return alloc[0].data + alloc[0].index -length; 
    }




#endif // MANNIX_LIB
