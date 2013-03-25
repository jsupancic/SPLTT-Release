// JSS3 2012-5-29
// fast hash using OpenSSL

#include "mex.h"
#include <openssl/md5.h>

typedef unsigned char uchar;

// hash = hashMat(mat);
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) 
{
    // check args
    if(nrhs != 1 || nlhs != 1)
	mexErrMsgTxt("syntax: hash = hashMat(mat)");

    // get data    
    // mxGetData
    void * data = mxGetData(prhs[0]);
    // mxGetNumberOfElements
    size_t numel = mxGetNumberOfElements(prhs[0]);
    // mxGetElementSize
    size_t elSz = mxGetElementSize(prhs[0]);

    // compute hash
    uchar hash[MD5_DIGEST_LENGTH+1/*in bytes*/];
    MD5((uchar*)data,elSz*numel,(uchar*)hash);
    hash[MD5_DIGEST_LENGTH] = 0;

    // extract hash to string
    // 1 8-bit byte 
    // 4 bits per hex char.
    char hashString[2*MD5_DIGEST_LENGTH+1];
    for(int iter = 0; iter < MD5_DIGEST_LENGTH; iter++)
    {
	snprintf(hashString+2*iter,3,"%02x",hash[iter]);
	//mexPrintf("hash[iter] = %02x\n",hash[iter]);
	//mexPrintf("hashString = %s\n",hashString);
    }
    hashString[2*MD5_DIGEST_LENGTH] = 0;

    // return
    plhs[0] = mxCreateString(hashString);
}
