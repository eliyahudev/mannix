#include "../include/cnn_inc.h"



int main(int argc, char const *argv[]) {

    #include "../include/mannix_allocation_setup.h"


    // declare and get access to matrix and tensors via pointer
    Tensor tens[1];

    // create matrix from exel file     
    FILE *imageFilePointer = fopen("../source/data_set_256_fasion_emnist.csv", "r");

    // set tensor size to 3 5x5 matricies 
    createTensor(5, 5, 3, tens, al, mat_al);
    setMatrixToTensor(tens, imageFilePointer, &label, 1);
        
    printf("\n matrix before maxpooling: \n");
    printTensor(tens);

    tensorMaxPool(tens,2,2,2);

    printf("\n result matrix after maxpooling: \n");
    printTensor(tens);

    // sanity check - make sure the data is stored sequntianly
    for (size_t i = 0; i < 12; i++) {
        printf("%d ,", tens->matrix[0].data[i]);
    }
    
    fclose(imageFilePointer);

    return 0;
}