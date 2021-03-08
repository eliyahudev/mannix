// MANNIX i/o addresses

#define GPP_BASE_ADDR   0x1A106000 // TODO 
#define CNN_ADDRX       GPP_BASE_ADDR +0X0004
#define CNN_ADDRY       GPP_BASE_ADDR +0X0008
#define CNN_ADDRZ       GPP_BASE_ADDR +0X000C
#define CNN_XM          GPP_BASE_ADDR +0X0010
#define CNN_XN          GPP_BASE_ADDR +0X0014
#define CNN_YM          GPP_BASE_ADDR +0X0018
#define CNN_YN          GPP_BASE_ADDR +0X001C
#define CNN_STRAT       GPP_BASE_ADDR +0X0020
#define CNN_DONE        GPP_BASE_ADDR +0X0024

#define POOL_ADDRX        GPP_BASE_ADDR +0X0028
#define POOL_ADDRZ      GPP_BASE_ADDR +0X002C
#define POOL_XM         GPP_BASE_ADDR +0X0030
#define POOL_XN         GPP_BASE_ADDR +0X0034  
#define POOL_PM         GPP_BASE_ADDR +0X0038
#define POOL_PN         GPP_BASE_ADDR +0X003C
#define POOL_START      GPP_BASE_ADDR +0X0040
#define POOL_DONE       GPP_BASE_ADDR +0X0044

#define ACTIV_ADDRX     GPP_BASE_ADDR +0X0048
#define ACTIV_XM        GPP_BASE_ADDR +0X004C
#define ACTIV_XN        GPP_BASE_ADDR +0X0050
#define ACTIV_START     GPP_BASE_ADDR +0X0054
#define ACTIV_DONE      GPP_BASE_ADDR +0X0058

#define FC_ADDRX        GPP_BASE_ADDR +0X005C
#define FC_ADDRY        GPP_BASE_ADDR +0X0060
#define FC_ADDRB        GPP_BASE_ADDR +0X0064
#define FC_ADDRZ        GPP_BASE_ADDR +0X0068
#define FC_XM           GPP_BASE_ADDR +0X006C
#define FC_YM           GPP_BASE_ADDR +0X0070
#define FC_YN           GPP_BASE_ADDR +0X0074
#define FC_BN           GPP_BASE_ADDR +0X0078
#define FC_START        GPP_BASE_ADDR +0X007C
#define FC_DONE         GPP_BASE_ADDR +0X0080

//---- program define ----
// #define MANNIX_CNN_F
// #define MANNIX_ACTIVE_F
// #define MANNIX_PULL_F
// #define MANNIX_FC_F

//---- dubaging defines ----
#define TEST // result example of few pictures
#define DEBUG // debug variable

//---- OS ----
#define WINDOWS_MANNIX
// #define DEBIAN

//---- environment setups----
#define VS_MANNIX // this flag must be set when using visual studio environment
#define DATA_TYPE float // type could be float or int
#define DISABLE_SCALE // if float is chosen set this flag which desable the activation

// ----- environment defines ----------
// memory size definitions
#define MANNIX_DATA_SIZE 500000 
#define MANNIX_MAT_SIZE 500
#define MANNIX_TEN_SIZE 500
// activation
#define NUM_RELU_DESCALE_BITS 5
#define RELU_SCALE ((int)(1<<NUM_RELU_DESCALE_BITS))
#define MAX_RELU_VAL ((int)(1<<NUM_RELU_DESCALE_BITS))
#define NUM_FINAL_DESCALE_BITS 9
#define FINAL_SCALE ((int)(1<<NUM_FINAL_DESCALE_BITS))
#define MAX_FINAL_VAL ((int)(127*FINAL_SCALE))