
//---- dubaging defines ----
// #define TEST // result example of few pictures
#define CMP_TEST //
//#define DEBUG // debug variable

#ifdef CMP_TEST
#define IFDEF_CMP_TEST(dump_call) dump_call
#else
#define IFDEF_CMP_TEST(dump_call) 
#endif


// #define  CSV

//---- OS ----
#define WINDOWS_MANNIX
// #define DEBIAN

//---- environment setups----

// #define VS_MANNIX

// #define MEM_DUMP_MODE // Dumps the model parameters loadable data vector , run once per model configuration.

#define MEM_LOAD_MODE  // Model parameters and data to be actively loaded , skip CSV read
#ifdef VS_MANNIX
#define MODEL_PARAMS_FILE "../../model_params_db/model_params_mfdb.txt"
#define DATASET_FILE "../../test_src/fashion_mnist_V1_mfds.txt"
#else
#define MODEL_PARAMS_FILE "../model_params_db/model_params_mfdb.txt"
#define DATASET_FILE "../test_src/fashion_mnist_V1_mfds.txt"
#endif

// ----- environment defines ----------
// memory size definitions
#define MANNIX_DATA_SIZE 53000 
#define MANNIX_MAT_SIZE 3000
#define MANNIX_TEN_SIZE 1000
// activation
#define WB_LOG2_SCALE 7
#define UINT_DATA_WIDTH 8
#define LOG2_RELU_FACTOR 1
#define EXP_UINT_DATA_WIDTH 1 << UINT_DATA_WIDTH
#define MAX_DATA_RANGE (EXP_UINT_DATA_WIDTH) - 1  


