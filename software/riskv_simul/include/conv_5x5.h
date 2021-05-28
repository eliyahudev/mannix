
#ifdef PULP_EXT // Works only for pulp ri5cy extensions

// Based on - https://github.com/pulp-platform/pulp-training/blob/master/convolution/solution/conv_kernels.c

typedef signed   char      Filtc;
typedef unsigned char      Pixel;
typedef signed   char      FiltcV     __attribute__((vector_size (4)));
typedef unsigned char      PixelV     __attribute__((vector_size (4)));

//----------------------------------------------------------------------------

// Used Compiler Pulp built-in macros

#define sumdotp(x, y, z)   __builtin_pulp_sdotusp4(x, y, z)

// Returns: z + ( (unsigned char)(x)[0]*(signed char)(y)[0] 
//               +(unsigned char)(x)[1]*(signed char)(y)[1] 
//               +(unsigned char)(x)[2]*(signed char)(y)[2] 
//               +(unsigned char)(x)[3]*(signed char)(y)[3])

#define dotp(x, y)         __builtin_pulp_dotusp4(x, y)       

// Returns: ( (unsigned char)(x)[0]*(signed char)(y)[0]
//          + (unsigned char)(x)[1]*(signed char)(y)[1] 
//          + (unsigned char)(x)[2]*(signed char)(y)[2] 
//          + (unsigned char)(x)[3]*(signed char)(y)[3])

#define shuffle(a, b, c)   __builtin_pulp_shuffle4b(a, b, c)

// Equivalent pseudo code
// char a[4] , b[4] , c[4] ;
// for (i=0;i++;i<3) vout[i] = (c[i] < 3) ? a[i] : b[i-4] ;

//---------------------------------------------------------------------------------------------------------

void __attribute__ ((noinline)) Conv5x5_Vector  (Pixel * In_Img, int * Out_Img, int R, int C, Filtc  * Kernel, int bias) {

  FiltcV flt_r0_c0to4, flt_r1_c0to4, flt_r2_c0to4, flt_r3_c0to4, flt_r4_c0to4, flt_c4_r0to4, flt_r4c4_0_0_0 ;
  PixelV win_r0_c0to4, win_r1_c0to4, win_r2_c0to4, win_r3_c0to4, win_r4_c0to4, win_c4_r0to4, win_r4c4_0_0_0 ;

  PixelV shift_mask = (PixelV){1, 2, 3, 4};

  int S1,S2;

  // Kernel assignment 
    
  flt_r0_c0to4 = *((FiltcV *) (&Kernel[ 0])) ; 
  flt_r1_c0to4 = *((FiltcV *) (&Kernel[ 5])) ; 
  flt_r2_c0to4 = *((FiltcV *) (&Kernel[10])) ; 
  flt_r3_c0to4 = *((FiltcV *) (&Kernel[15])) ; 
  flt_r4_c0to4 = *((FiltcV *) (&Kernel[20])) ; 
  
  // Handling most right 5th column in kernel                    
  flt_c4_r0to4 = (FiltcV){Kernel[4],Kernel[9],Kernel[14],Kernel[19]} ;
  flt_r4c4_0_0_0  = (FiltcV){Kernel[24],0,0,0};  

  //image window scan_is
  
  for (int c=0; c < C-4; c++) {

    int ii = c ; // index of flattened input matrix (upper left corner of window)    
    int oi = c ; // index of flattened output matrix 
    

    // Initial window per column
    
    win_r0_c0to4 = *((PixelV *) (&In_Img[ii+(0*C)])) ;  
    win_r1_c0to4 = *((PixelV *) (&In_Img[ii+(1*C)])) ;  
    win_r2_c0to4 = *((PixelV *) (&In_Img[ii+(2*C)])) ;  
    win_r3_c0to4 = *((PixelV *) (&In_Img[ii+(3*C)])) ;        
    win_r4_c0to4 = *((PixelV *) (&In_Img[ii+(4*C)])) ; 
    
    // Handling most right 5th column in window
    win_c4_r0to4    =  (PixelV){In_Img[ii+4],In_Img[ii+4+C],In_Img[ii+4+(2*C)],In_Img[ii+4+(3*C)]}; 
    win_r4c4_0_0_0  =  (PixelV){In_Img[ii+4+(4*C)],0,0,0};    
      
    for (int r=0; r < R-4-1; r++) {  // Notice '-1' because one iteration is executed external to the loop

        // We stagger calculation with window down shifting for efficient Dual-IssueIssue utilization 
        // We break summing to S1 and S2 for better Dual-Issue utilization.
       
        S1 = dotp(win_r0_c0to4,  flt_r0_c0to4);
        win_r0_c0to4 = win_r1_c0to4 ;          

        S2 = dotp(win_r1_c0to4,  flt_r1_c0to4);
        win_r1_c0to4 = win_r2_c0to4 ;        
        
        S1 = sumdotp(win_r2_c0to4,  flt_r2_c0to4,S1);
        win_r2_c0to4 = win_r3_c0to4 ;        
        
        S2 = sumdotp(win_r3_c0to4,  flt_r3_c0to4,S2);
        win_r3_c0to4 = win_r4_c0to4 ;        
        
        S1 = sumdotp(win_r4_c0to4,  flt_r4_c0to4 ,S1);
        win_r4_c0to4 = *((PixelV *) (&In_Img[ii+(4*C)]));           
                                                  
        S2 = sumdotp(win_c4_r0to4  ,flt_c4_r0to4 ,S2);
        win_c4_r0to4    = shuffle(win_c4_r0to4, win_r4c4_0_0_0, shift_mask);          
        
        S1 = sumdotp(win_r4c4_0_0_0,flt_r4c4_0_0_0,S1);
        win_r4c4_0_0_0  = (PixelV){In_Img[ii+4+(4*C)],0,0,0};        
                
        Out_Img[oi] = S1 + S2 + bias;

        // We have moved down the image window , a new 4-byte vector is appended at the bottom, calculate towards next iteration
           
        ii = ii+C ;      // update input matrix flat index to one row below at same column (C == num columns == input matrix width)
        oi = oi+C-4 ;    // update output matrix flat index to one row below at same column (C-4 == num columns == output matrix width)        
        
     } //for r ....
    
    // exit rows loop per column

     S1 = dotp   (win_r0_c0to4,  flt_r0_c0to4);
     S2 = dotp(win_r1_c0to4,     flt_r1_c0to4);
     S1 = sumdotp(win_r2_c0to4,   flt_r2_c0to4 ,  S1);
     S2 = sumdotp(win_r3_c0to4,   flt_r3_c0to4 ,  S2);
     S1 = sumdotp(win_r4_c0to4,   flt_r4_c0to4 ,  S1);
                                                
     S2 = sumdotp(win_c4_r0to4  , flt_c4_r0to4 ,  S2);
     S1 = sumdotp(win_r4c4_0_0_0, flt_r4c4_0_0_0, S1);
                                      
     Out_Img[oi] = S1 + S2 + bias;
            
  } // for c ....
}
#endif