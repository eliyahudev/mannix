

void* matrixFCNActivate(Matrix_uint8* input_matrix, Matrix_int8* weight_matrix, Matrix_int32* bias_vector, Matrix_uint8* result_matrix ) {

    volatile unsigned char ** fc_addrx = (volatile unsigned char **)(FC_ADDRX);
    volatile signed char ** fc_addry = (volatile signed char **)(FC_ADDRY);
    volatile unsigned char ** fc_addrz = (volatile unsigned char **)(FC_ADDRZ);
    volatile signed int **  fc_addrb = (volatile signed int ** )(FC_ADDRB);
    volatile signed int * fc_xm = (volatile signed int * )(FC_XM);
    volatile signed int * fc_xn = (volatile signed int * )(FC_XN);
    volatile signed int * fc_ym = (volatile signed int * )(FC_YM);
    volatile signed int * fc_yn = (volatile signed int * )(FC_YN);
    volatile signed int * fc_start = (volatile signed int * )(FC_START);
    volatile signed int * fc_done = (volatile signed int * )(FC_DONE);

    int done;
    // * fc_start = (volatile signed int * )(FC_START);
    * fc_done = (volatile signed int * )(FC_DONE);
    // while(!(done = fc_done)); // TODO - add after first test

    * fc_addrx = input_matrix->data;
    * fc_addry = weight_matrix->data;
    * fc_addrz = result_matrix->data;
    * fc_addrb = bias_vector->data;
    * fc_xm = input_matrix->rows;
    * fc_ym = weight_matrix->rows;
    * fc_yn = weight_matrix->cols;
    * fc_start = 1;
    for (size_t i = 0; i < 1000; i++) {
        int x = i * i;
    }
    while(!(done = fc_done)); // TODO - add after first test
    bm_printf("================ done ======================\n");

}
