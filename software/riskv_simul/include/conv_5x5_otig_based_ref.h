

#ifdef PULP_EXT // Works only for pulp ri5cy extensions

// Based on - https://github.com/pulp-platform/pulp-training/blob/master/convolution/solution/conv_kernels.c


typedef signed   char      Filtc;
typedef unsigned char      Pixel;
typedef signed   char      FiltcV     __attribute__((vector_size (4)));
typedef unsigned char      PixelV     __attribute__((vector_size (4)));

// Used Compiler Pulp built-in macros

#define sumdotp(a, b, c)   __builtin_pulp_sdotusp4(a, b, c)

// Returns: z + ( (unsigned char)(x)[0]*(char)(y)[0] 
//               +(unsigned char)(x)[1]*(char)(y)[1] 
//               +(unsigned char)(x)[2]*(char)(y)[2] 
//               +(unsigned char)(x)[3]*(char)(y)[3])


#define dotp(a, b)         __builtin_pulp_dotusp4(a, b)       

// Returns: ( (unsigned char)(x)[0]*(char)(y)[0]
//          + (unsigned char)(x)[1]*(char)(y)[1] 
//          + (unsigned char)(x)[2]*(char)(y)[2] 
//          + (unsigned char)(x)[3]*(char)(y)[3])


#define shuffle(a, b, c)   __builtin_pulp_shuffle4b(a, b, c)

// Construct a permutation of elements from two vectors and return a vector of the same type as the input vector(s). 
// The mask is an integral vector with the same width (W) and element count (N) as the output vector.
// The elements of the input vectors are numbered in memory ordering of vec0 beginning at 0 and vec1 beginning at N. 
// The elements of mask are considered modulo 2*N.

// Equivalent pseudo code
// char a[4] , b[4] , m[4] ;
// for (i=0;i++;i<3) vout[i] = (mask[i] < 3) ? a[i] : b[i-4] ;

void __attribute__ ((noinline)) Conv5x5_Vector (Pixel * In_Img, int * Out_Img, int R, int C, Filtc  * Kernel, int bias)
{

  FiltcV coeff_0, coeff_1, coeff_2, coeff_3, coeff_4, coeff_5, coeff_6;
  PixelV Img_0, Img_1, Img_2, Img_3, Img_4, Img_5, Img_6;
  PixelV new_data1, new_data2;
  int r, c, t;
  PixelV mask0;
  int S;

  coeff_0 = *((FiltcV *) (&Kernel[ 0]));
  coeff_1 = *((FiltcV *) (&Kernel[ 5]));
  coeff_2 = *((FiltcV *) (&Kernel[10]));
  coeff_3 = *((FiltcV *) (&Kernel[15]));
  coeff_4 = *((FiltcV *) (&Kernel[20]));
  coeff_5 = (FiltcV)     { Kernel[4],  Kernel[9], Kernel[14], Kernel[19] };
  coeff_6 = (FiltcV)     { Kernel[24], 0,         0,          0 };
  mask0 = (PixelV){1, 2, 3, 4};

  //image board is black
  for (c=0; c < C-4; c++) {

    Img_0   = *((PixelV *) (&In_Img[c])     );
    Img_1   = *((PixelV *) (&In_Img[c+R])   );
    Img_2   = *((PixelV *) (&In_Img[c+2*R]) );
    Img_3   = *((PixelV *) (&In_Img[c+3*R]) );
    Img_4   = *((PixelV *) (&In_Img[c+4*R]) );
    Img_5   = (PixelV)     { In_Img[c+4],     In_Img[c+4+R], In_Img[c+4+2*R], In_Img[c+4+3*R] };
    Img_6   = (PixelV)     { In_Img[c+4+4*R], 0,             0,               0 };

    for (r=1; r < R-4; r++) {

        t = (r+1)*R + c+2;
        S = dotp(Img_0,coeff_0);
        S = sumdotp(Img_1,coeff_1, S);
        S = sumdotp(Img_2,coeff_2, S);
        S = sumdotp(Img_3,coeff_3, S);
        S = sumdotp(Img_4,coeff_4, S);
        S = sumdotp(Img_5,coeff_5, S);
        S = sumdotp(Img_6,coeff_6, S);

        Out_Img[t] = S + bias;

        new_data1 = *((PixelV *) (&In_Img[c+(r+4)*R]));
        new_data2 =   (PixelV  ) {In_Img[c+4+(r+4)*R], 0, 0, 0};

        // Move the window
        /*
          Seven vectors:
          Img_0 = {A0, A1, A2, A3}
          Img_1 = {B0, B1, B2, B3}
          Img_2 = {C0, C1, C2, C3}
          Img_3 = {D0, D1, D2, D3}
          Img_4 = {E0, E1, E2, E3}
          Img_5 = {F0, F1, F2, F3}
          Img_6 = {G0,  0,  0,  0}
          
          Current Window:
          XX XX XX XX XX
          A0 A1 A2 A3 F0
          B0 B1 B2 B3 F1
          C0 C1 C2 C3 F2
          D0 D1 D2 D3 F3
          E0 E1 E2 E3 G0
          H0 H1 H2 H3 G1
          XX XX XX XX XX
          
          We want to load next line (H0, H1, H2, H3, G1)
          in vectors new_data1 and new_data2
          
          new_data1 = {H0, H1, H2, H3}
          new_data2 = {G1,  0,  0,  0}
          
          Move each vector one line down and shuffle the vertical vector
          Img_0 = {B0, B1, B2, B3}
          Img_1 = {C0, C1, C2, C3}
          Img_2 = {D0, D1, D2, D3}
          Img_3 = {E0, E1, E2, E3}
          Img_4 = {H0, H1, H2, H3}
          Img_5 = {F1, F2, F3, G0}
          Img_5 = {G1,  0,  0,  0}
        */

        Img_0 = Img_1;
        Img_1 = Img_2;
        Img_2 = Img_3;
        Img_3 = Img_4;
        Img_4 = new_data1;
        Img_5 = shuffle(Img_5, Img_6,  mask0);
        Img_6 = new_data2;

    }
    //last iteration
    t = (r+1)*R + c+2;
    S = dotp(Img_0,coeff_0);
    S = sumdotp(Img_1,coeff_1, S);
    S = sumdotp(Img_2,coeff_2, S);
    S = sumdotp(Img_3,coeff_3, S);
    S = sumdotp(Img_4,coeff_4, S);
    S = sumdotp(Img_5,coeff_5, S);
    S = sumdotp(Img_6,coeff_6, S);


    Out_Img[t] = S + bias;
  }
}
#endif