#ifndef MANNIX_SRC_SETUP
#define MANNIX_SRC_SETUP
char file_out[80] ;

#ifndef MEM_LOAD_MODE
  #ifdef VS_MANNIX
      #ifdef CMP_TEST  
      FILE* imageFilePointer = fopen("../../test_src/img_9558.csv", "r");

      #else
      FILE* imageFilePointer = fopen("../../test_src/data_set_256_fasion_emnist.csv", "r");
      #endif
      char* path_in = { "../../../python/csv_dumps/scaled_int/" };
      char * path_out = {"../../test_products/"} ;    
  #else
      #ifdef CMP_TEST  
      FILE* imageFilePointer = fopen("../test_src/img_9558.csv", "r");
      #else
      FILE* imageFilePointer = fopen("../test_src/data_set_256_fasion_emnist.csv", "r");
      #endif
      char* path_in = { "../../python/csv_dumps/scaled_int/" };
      char * path_out = {"../test_products/"} ;

  #endif
#else
    FILE* imageFilePointer = fopen(DATASET_FILE,"r");  // @MEM_LOAD_MODE (File name defined at man_def.h)
    char* path_in = { "../../python/csv_dumps/scaled_int/" };
    char * path_out = {"../test_products/"} ;
    // char file_out[80] ;

#endif
#endif
