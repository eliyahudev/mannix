
void create4DTensor(Tensor4D* tens_4d, int rows, int cols, int depth, int dim, Allocator* al, MatAllocator* mat_alloc, TensorAllocator* tens_alloc) {
    tens_4d->rows = rows;
    tens_4d->cols = cols;
    tens_4d->depth = depth;
    tens_4d->dim = dim;
    tens_4d->tensor = mannixTensorMalloc(tens_alloc, dim);

    for(int i = 0; i < tens_4d->dim; i++)
        createTensor(rows, cols, depth, &tens_4d->tensor[i], al, mat_alloc);
}


void set4DTensor(Tensor4D* tens_4d, char* path, int layer) {

    int label[1];
    FILE* fd;

    // set matricies
    for(int i = 0; i < tens_4d->dim; i++)
        for(int j = 0; j < tens_4d->depth; j++) {
            fd = createFd(path, layer, i, j);  // get file descriptors for csv conv files
            getMatrix(&tens_4d->tensor[i].matrix[j], fd, label,-1, 1);
#ifdef DEBUG
            printf("colsing fd: %d\n", fd);
            fclose(fd);
#endif
        }
}


void printD4Tensor(Tensor4D* tens_4d) {

    printf("tensor{\n");    
    for(int i = 0; i < tens_4d->dim; i++) {
        printf("\n[");
        printTensor(&tens_4d->tensor[i]);
        printf(" ]\n");
    }
    printf("}\n");
    printf("rows size: %d columns size: %d depth size: %d dim: %d \n\n",tens_4d->rows,tens_4d->cols,tens_4d->depth,tens_4d->dim);

}
