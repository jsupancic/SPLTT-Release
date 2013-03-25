/*************************************************************************************
 *
 * MATLAB (R) is a trademark of The Mathworks (R) Corporation
 *
 * Function:    uninit
 * Filename:    uninit.c
 * Programmer:  James Tursa
 * Version:     1.00
 * Date:        May 03, 2011
 * Copyright:   (c) 2011 by James Tursa, All Rights Reserved
 *
 *  This code uses the BSD License:
 *
 *  Redistribution and use in source and binary forms, with or without 
 *  modification, are permitted provided that the following conditions are 
 *  met:
 *
 *     * Redistributions of source code must retain the above copyright 
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright 
 *       notice, this list of conditions and the following disclaimer in 
 *       the documentation and/or other materials provided with the distribution
 *      
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
 *  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
 *  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
 *  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
 *  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
 *  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
 *  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
 *  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
 *  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
 *  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
 *  POSSIBILITY OF SUCH DAMAGE.
 *
 * Building:
 *
 * UNINIT is typically self building. That is, the first time you call UNINIT,
 * the uninit.m file recognizes that the mex routine needs to be compiled and
 * then the compilation will happen automatically. UNINIT uses the undocumented
 * MATLAB API function mxCreateUninitNumericMatrix. It has been tested in PC
 * versions R2006b through R2011a, but may not work in future versions of MATLAB.
 *
 * Syntax (nearly identical to the ZEROS function)
 *
 *  B = uninit
 *  B = uninit(n)
 *  B = uninit(m,n)
 *  B = uninit([m n])
 *  B = uninit(m,n,p,...)
 *  B = uninit([m n p ...])
 *  B = uninit(size(A))
 *  B = uninit(m, n,...,classname)
 *  B = uninit([m,n,...],classname)
 *  B = uninit(m, n,...,complexity)
 *  B = uninit([m,n,...],complexity)
 *  B = uninit(m, n,...,classname,complexity)
 *  B = uninit([m,n,...],classname,complexity)
 * 
 *  Description
 * 
 *  B = uninit
 *      Returns a 1-by-1 scalar uninitialized value.
 *
 *  B = uninit(n)
 *      Returns an n-by-n matrix of uninitialized values. An error message
 *      appears if n is not a scalar. 
 *
 *  B = uninit(m,n) or B = uninit([m n])
 *      Returns an m-by-n matrix of uninitialized values. 
 *
 *  B = uninit(m,n,p,...) or B = uninit([m n p ...])
 *      Returns an m-by-n-by-p-by-... array of uninitialized values. The
 *      size inputs m, n, p, ... should be nonnegative integers. Negative
 *      integers are treated as 0.
 *
 *  B = uninit(size(A)) 
 *      Returns an array the same size as A consisting of all uninitialized
 *      values.
 *
 *  If any of the numeric size inputs are empty, they are taken to be 0.
 *
 *  The optional classname argument can be used with any of the above.
 *  classname is a string specifying the data type of the output.
 *  classname can have the following values:
 *          'double', 'single', 'int8', 'uint8', 'int16', 'uint16',
 *          'int32', 'uint32', 'int64', 'uint64', 'logical', or 'char'.
 *          (Note: 'logical' and 'char' are not allowed in the ZEROS function)
 *  The default classname is 'double'.
 *
 *  The optional complexity argument can be used with any of the above.
 *  complexity can be 'real' or 'complex', except that 'logical' and 'char'
 *  outputs cannot be complex. (this option not allowed in the ZEROS function)
 *  The default complexity is 'real'.
 *
 * UNINIT is very similar to the ZEROS function, except that UNINIT returns
 * an uninitialized array instead of a zero-filled array. Thus, UNINIT is
 * faster than the ZEROS function for large size arrays. Since the return
 * variable is uninitialized, the user must take care to assign values to
 * the elements before using them. UNINIT is useful for preallocation of an
 * array where you know the elements will be assigned values before using them.
 *
 * Example
 *
 *   x = uninit(2,3,'int8');
 *
 * Change Log:
 * 2011/May/03 --> 1.00, Initial Release
 *
 ****************************************************************************/

/* Includes ----------------------------------------------------------- */

#include <string.h>
#include <stddef.h>
#include <ctype.h>
#include "mex.h"

/* Macros ------------------------------------------------------------- */

#ifndef  MWSIZE_MAX
#define  mwSize  int
#endif

/* Undocumented Function mxCreateUninitNumericMatrix ------------------ */

mxArray *mxCreateUninitNumericMatrix(mwSize m, mwSize n, mxClassID classid,
                                     mxComplexity ComplexFlag);

/* myCreateUninitNumericArray ----------------------------------------- */
/*                                                                      */
/* Creates uninitialized array using above function. Essentially, this  */
/* is a replacement for mxCreateUninitNumericArray, which is only       */
/* available for R2008b and later. For two dimensions just call the     */
/* mxCreateUninitNumericMatrix function directly. For more than two     */
/* dimensions, first multiply all the dimensions to get a single value, */
/* pass that to mxCreateUninitNumericMatrix, then set the dimensions of */
/* the result to the actual desired dimensions.                         */

mxArray *myCreateUninitNumericArray(mwSize ndim, const mwSize *dims,
                                    mxClassID classid, mxComplexity ComplexFlag)
{
    mxArray *mx;
    mwSize i, m, n;
    
    if( ndim <= 0 ) {
        mx = mxCreateUninitNumericMatrix(0,0,classid,ComplexFlag);
    } else if( ndim == 1 ) {
        mx = mxCreateUninitNumericMatrix(dims[0],1,classid,ComplexFlag);
    } else if( ndim == 2 ) {
        mx = mxCreateUninitNumericMatrix(dims[0],dims[1],classid,ComplexFlag);
    } else {
        m = 1;
        for( i=0; i<ndim; i++ ) {
            n = m;
            m *= dims[i];
            if( dims[i] && n != m / dims[i] ) { /* Check for overflow */
                mexErrMsgTxt("Maximum variable size allowed by the program is exceeded.");
            }
        }
        mx = mxCreateUninitNumericMatrix(m,1,classid,ComplexFlag);
        if( mxSetDimensions(mx,dims,ndim) ) {
            mxDestroyArray(mx);
            mx = NULL;
        }
    }
    return mx;
}

/* Gateway ------------------------------------------------------------ */

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
	mxArray *mx;
    mwSize i, j, k, n, ndim;
	mwSize *dims;
	mxClassID classid;
	mxComplexity ComplexFlag;
	char *cp, *xp;
	double d;
	double *dp;
	int warning1 = 1;
	int warning2 = 1;
	int gotclass = 0;
	int gotcomplexity = 0;

/* Count the number of numeric arguments */

	n = 0;
	for( i=0; i<nrhs; i++ ) {
		if( mxIsNumeric(prhs[i]) ) {
			k = i;
			n++;
		}
	}

/* If the number of numeric arguments is 0, then return a scalar result */

	if( n == 0 ) {
		ndim = 2;
		dims = mxMalloc(ndim*sizeof(*dims));
		dims[0] = 1;
		dims[1] = 1;

/* If the number of numeric arguments is 1, allow for a row vector argument */

	} else if( n == 1 ) {
		if( mxGetNumberOfDimensions(prhs[k]) != 2 || mxGetM(prhs[k]) != 1 ) {
			mexErrMsgTxt("Size vector must be a row vector with integer elements.");
		}
		if( mxIsDouble(prhs[k]) ) {
			mx = prhs[k];
		} else {
			mexCallMATLAB(1,&mx,1,prhs+k,"double");
		}
		ndim = mxGetN(mx);
		if( ndim == 1 ) {
			ndim = 2;
			dims = mxMalloc(ndim*sizeof(*dims));
			d = mxGetScalar(mx);
			dims[0] = (mwSize) d;
            if( dims[0] < 0 && d > 0.0 || dims[0] > 0 && d < 0.0 ) { /* Check for overflow */
                mexErrMsgTxt("Maximum variable size allowed by the program is exceeded.");
            }
			if( dims[0] != d && warning1 ) {
				warning1 = 0;
				mexWarnMsgTxt("Size vector should be a row vector with integer elements.");
			}
			if( dims[0] < 0 ) dims[0] = 0;
			dims[1] = dims[0];
		} else {
			dims = mxMalloc(ndim*sizeof(*dims));
			dp = mxGetPr(mx);
			for( i=0; i<ndim; i++ ) {
				dims[i] = (mwSize) dp[i];
                if( dims[i] < 0 && dp[i] > 0.0 || dims[i] > 0 && dp[i] < 0.0 ) { /* Check for overflow */
                    mexErrMsgTxt("Maximum variable size allowed by the program is exceeded.");
                }
				if( dims[i] != dp[i] && warning1 ) {
					warning1 = 0;
					mexWarnMsgTxt("Size vector should be a row vector with integer elements.");
				}
				if( dims[i] < 0 ) dims[i] = 0;
			}
		}
		if( mx != prhs[k] ) {
			mxDestroyArray(mx);
		}

/* If the number of numeric arguments is > 1, then each numeric argument     */
/* will contribute one number to the resulting dimensions. Empty or negative */
/* arguments are taken to be 0. A warning is given for non-integral or non-  */
/* scalar arguments.                                                         */

	} else {
		ndim = n;
		dims = mxMalloc(ndim*sizeof(*dims));
		k = 0;
		for( i=0; i<nrhs; i++ ) {
			if( mxIsNumeric(prhs[i]) ) {
				if( mxIsEmpty(prhs[i]) ) {
					dims[k++] = 0;
				} else {
					if( mxGetNumberOfElements(prhs[i]) > 1 && warning2 ) {
						warning2 = 0;
						mexWarnMsgTxt("Input arguments must be scalar.");
					}
					d = mxGetScalar(prhs[i]);
					dims[k] = (mwSize) d;
                    if( dims[k] < 0 && d > 0.0 || dims[k] > 0 && d < 0.0 ) { /* Check for overflow */
                        mexErrMsgTxt("Maximum variable size allowed by the program is exceeded.");
                    }
					if( dims[k] != d && warning1 ) {
						warning1 = 0;
						mexWarnMsgTxt("Input arguments must be integer elements.");
					}
					if( dims[k] < 0 ) dims[k] = 0;
					k++;
				}
			}
		}
	}

/* Now process the char arguments to get the desired class and complexity.   */
/* The default is double real.  Allow logical and char classes also, since   */
/* the mxCreateUninitNumericMatrix function seems to allow them OK. This,    */
/* and the complexity input, are extensions not available in zeros function. */

	for( i=0; i<nrhs; i++ ) {
		if( mxIsChar(prhs[i]) ) {
			xp = cp = mxArrayToString(prhs[i]);
			while( *xp ) {
				*xp = tolower( *xp );
				xp++;
			}
			if(        strcmp(cp,"double") == 0 ) {
				gotclass++;
				classid = mxDOUBLE_CLASS;
			} else if( strcmp(cp,"single") == 0 ) {
				gotclass++;
				classid = mxSINGLE_CLASS;
			} else if( strcmp(cp,"int8") == 0 ) {
				gotclass++;
				classid = mxINT8_CLASS;
			} else if( strcmp(cp,"uint8") == 0 ) {
				gotclass++;
				classid = mxUINT8_CLASS;
			} else if( strcmp(cp,"int16") == 0 ) {
				gotclass++;
				classid = mxINT16_CLASS;
			} else if( strcmp(cp,"uint16") == 0 ) {
				gotclass++;
				classid = mxUINT16_CLASS;
			} else if( strcmp(cp,"int32") == 0 ) {
				gotclass++;
				classid = mxINT32_CLASS;
			} else if( strcmp(cp,"uint32") == 0 ) {
				gotclass++;
				classid = mxUINT32_CLASS;
			} else if( strcmp(cp,"int64") == 0 ) {
				gotclass++;
				classid = mxINT64_CLASS;
			} else if( strcmp(cp,"uint64") == 0 ) {
				gotclass++;
				classid = mxUINT64_CLASS;
			} else if( strcmp(cp,"char") == 0 ) {
				gotclass++;
				classid = mxCHAR_CLASS;
			} else if( strcmp(cp,"logical") == 0 ) {
				gotclass++;
				classid = mxLOGICAL_CLASS;
			} else if( strcmp(cp,"real") == 0 ) {
				gotcomplexity++;
				ComplexFlag = mxREAL;
			} else if( strcmp(cp,"complex") == 0 ) {
				gotcomplexity++;
				ComplexFlag = mxCOMPLEX;
			} else {
				mexErrMsgTxt("Trailing string input must be a valid class name or complexity.");
			}
			mxFree(cp);
		} else if( !mxIsNumeric(prhs[i]) ) {
			mexErrMsgTxt("Leading inputs must be numeric.");
		}
	}

/* Check for inconsistent arguments */

	if( gotclass == 0 ) {
		classid = mxDOUBLE_CLASS;
	} else if( gotclass > 1 ) {
		mexErrMsgTxt("Too many class inputs.");
	}
	if( gotcomplexity == 0 ) {
		ComplexFlag = mxREAL;
	} else if( gotcomplexity > 1 ) {
		mexErrMsgTxt("Too many complexity inputs.");
	}
	if( ComplexFlag == mxCOMPLEX && (classid == mxCHAR_CLASS || classid == mxLOGICAL_CLASS) ) {
		mexErrMsgTxt("Char and Logical class variables cannot be complex.");
	}

/* Create the uninitialized output array */

	plhs[0] = myCreateUninitNumericArray(ndim, dims, classid, ComplexFlag);
	mxFree(dims);

}
