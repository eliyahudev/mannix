// #ifndef CNN_H
// #define CNN_H



// // ------------------------------------ MANNIX FUNCTIONS -------------------------------------------------
// void cnnConvolutionLayer(Matrix_uint8* input_matrix, Matrix_int8* weight_matrix, Matrix_int32* result_matrix, Allocator_int32* al) {

//     #ifdef MANNIX_CNN_F
//         volatile signed start = 1;
//         volatile signed done = 0; 
//         while (start)
//             MANNIX_convolution_layer(input_matrix->data, weight_matrix->data, result_matrix->data, input_matrix->rows, input_matrix->cols,
//                 weight_matrix->rows, weight_matrix->cols, start, done);
//         while (!done); 
//     #else
//         // matrixConvolution(input_matrix, weight_matrix, result_matrix, al);
//     #endif

//     #ifdef TEST
//         printMatrix_int32(result_matrix);
//     #endif
// }

// /* TODO - delete this function if it's not needed
// void  nonLinearityActivation(Matrix* input_matrix){

//     #ifdef MANNIX_ACTIVE_F
//         volatile signed start = 1;
//         volatile signed done = 0; 
//         while (start)
//             MANNIX_non_linearity_activation(input_matrix->data, input_matrix->rows, input_matrix->cols, start, done);
//         while (!done); 
//     #else
//         mannixRalu(input_matrix);
//     #endif

//     #ifdef TEST
//         printMatrix(input_matrix);
//     #endif
// }
// */
// void pullLayer_uint8(Matrix_uint8* input_matrix, Matrix_uint8* result_matrix, Allocator_uint8* al, int p_m, int p_n, int stride) {
//     #ifdef MANNIX_PULL_F
//         volatile signed start = 1;
//         volatile signed done = 0; 
//         while (start)
//             MANNIX_pull_layer_uint8(input_matrix->data, input_matrix->rows, input_matrix->cols, p_m, p_n, start, done);
//         while (!done); 
//     #else
//        // matrixMaxPool(input_matrix, p_m, p_n, stride);
//     #endif
    
//     #ifdef TEST
//         printMatrix_uint8(result_matrix);
//     #endif
// }

// void fc(Matrix_uint8* input_matrix, Matrix_int8* weight_matrix, Matrix_int32* bias_vector, Matrix_int32* result_matrix, Allocator_int32* al) {
//     #ifdef MANNIX_FC_F
//         volatile signed start = 1;
//         volatile signed done = 0; 
//         while (start)
//             MANNIX_fully_conneted();
//         while (!done); 
//     #else
//         printf("");
//         //fullyConnected(input_matrix, weight_matrix, bias_vector, result_matrix, al);
//     #endif

// }
// #endif // CNN_H

// // todo - create multiple filter function for convolution