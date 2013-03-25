#include <math.h>
#include <stdint.h>
#include "mex.h"
#include "matrix.h"

#define MAX(A,B) ((A) < (B) ? (B) : (A))
#define MIN(A,B) ((A) > (B) ? (B) : (A))

// Undocumented Features!
//extern int mxUnshareArray(mxArray *pr, int noDeepCopy);    // true if not successful
//extern bool mxUnshareArray(const mxArray *pr, const bool noDeepCopy);
extern "C" int mxUnshareArray(mxArray *pa, int level);
extern "C" int mxIsSharedArray(mxArray* pa);
extern "C" mxArray *mxCreateSharedDataCopy(const mxArray *pr);

// x(:,1:length(I)) = x(:,I);
// qp_one_c(qp.x,qp.b,qp.d,qp.a,qp.w,qp.sv,qp.l,qp.C,I);
void mexFunction( int nlhs, mxArray *plhs[],
                  int nrhs, const mxArray *prhs[] )
{
  if (nlhs < 5) mexErrMsgTxt("qp_one_c.cc: Incorrect number of output arguments.");
  if (nrhs < 9) mexErrMsgTxt("qp_one_c.cc: Incorrect number of input arguments.");

  // prevent erronous sharing.
  mxArray *Areturn, *Wreturn, *SVreturn, *Lreturn;
  Areturn = mxCreateSharedDataCopy(prhs[3]);
  Wreturn = mxCreateSharedDataCopy(prhs[4]);
  SVreturn = mxCreateSharedDataCopy(prhs[5]);
  Lreturn = mxCreateSharedDataCopy(prhs[6]);
  mxUnshareArray(Areturn, 0);
  mxUnshareArray(Wreturn, 0);
  mxUnshareArray(SVreturn, 0);
  mxUnshareArray(Lreturn, 0);

  float  const *X  = (float  *)mxGetPr(prhs[0]);
  float  const *B  = (float  *)mxGetPr(prhs[1]);
  double const *D  = (double *)mxGetPr(prhs[2]);
  double *A  = (double *)mxGetPr(Areturn);
  double *W  = (double *)mxGetPr(Wreturn);
  bool   *SV = (bool   *)mxGetPr(SVreturn);
  double *L  = (double *)mxGetPr(Lreturn);
  double  C  = (double  )mxGetScalar(prhs[7]);
  double const *I  = (double *)mxGetPr(prhs[8]);

  if (mxIsSingle(prhs[0])  == false) mexErrMsgTxt("Argument 0 is not single.");
  if (mxIsSingle(prhs[1])  == false) mexErrMsgTxt("Argument 1 is not single.");
  if (mxIsDouble(prhs[2])  == false) mexErrMsgTxt("Argument 2 is not double.");
  if (mxIsDouble(prhs[3])  == false) mexErrMsgTxt("Argument 3 is not double.");
  if (mxIsDouble(prhs[4])  == false) mexErrMsgTxt("Argument 4 is not double.");
  if (mxIsLogical(prhs[5]) == false) mexErrMsgTxt("Argument 6 is not logical.");
  if (mxIsDouble(prhs[6])  == false) mexErrMsgTxt("Argument 7 is not double.");
  if (mxIsDouble(prhs[7])  == false) mexErrMsgTxt("Argument 8 is not double.");
  if (mxIsDouble(prhs[8])  == false) mexErrMsgTxt("Argument 9 is not double.");

  mwSize m = mxGetM(prhs[0]);
  mwSize n = MAX(mxGetN(prhs[8]),mxGetM(prhs[8]));

  double loss = 0;
  //printf("Intro: (m,n,C) = (%d,%d,%g)\n",m,n,C);
  
  for (int cnt = 0; cnt < n; cnt++) {
    // Use C indexing
    int i = (int)I[cnt] - 1;
    double G = -(double)B[i];
    float const *x = X + m*i;
    
    for (int d = 0; d < m; d++) {
      G += W[d] * (double)x[d];
      //printf("(%g,%g,%g)",G,W[d],x[d]);
    }
    
    double PG = G;
    
    if ((A[i] == 0 && G >= 0) || (A[i] == C && G <= 0)) {
      PG = 0;
    }

    if (A[i] == 0 && G > 0) {
      SV[i] = false;
    }

    if (G < 0) {
      loss -= G;
    }

    //printf("[%d,%d,%g,%g,%g]\n",cnt,i,G,PG,A[i]);
    if (PG > 1e-12 || PG < -1e-12) {
      double dA = A[i];      
      A[i] = MIN ( MAX ( A[i] - G/D[i], 0 ) , C );
      dA   = A[i] - dA;
      L[0] += dA * (double) B[i];
      //printf("%g,%g,%g,%g\n",A[i],B[i],dA,*L);
      for (int d = 0; d < m; d++) {
	W[d] += dA * (double) x[d];
      }
    }
  }

  // pack the output arguments...
  plhs[0] = mxCreateDoubleScalar(loss);
  plhs[1] = Areturn;
  plhs[2] = Wreturn;
  plhs[3] = SVreturn;
  plhs[4] = Lreturn;
}

/* Mex code equivalent to below
% Perform one pass through variables indicated by binary mask
for i = I,
  % Compute clamped gradient
  G = qp.w'*qp.x(:,i) - qp.b(i);
  if (qp.a(i) == 0 && G >= 0) || (qp.a(i) == qp.C && G <= 0),
    PG = 0;
  else
    PG = G;
  end
  if (qp.a(i) == 0 && G > 0),
    qp.sv(i) = 0;
  end
  if G < 0,
    loss = loss - G;
  end
  % Update alpha,w, dual objective, support vector
  if (abs(PG) > 1e-12)
    a = qp.a(i);
    qp.a(i) = min(max(qp.a(i) - G/qp.d(i),0),qp.C);
    qp.w = qp.w + (qp.a(i) - a)*qp.x(:,i);
    qp.l = qp.l + (qp.a(i) - a)*qp.b(i);
  end
*/
