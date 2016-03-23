/**
 * JSS3 2012-5-28
 * Do greedy non-maximumal suppression
 **/

#include "mex.h"
#include "math.h"
#include <vector>
#include <limits>
#include "../mex/compat.h"

static const mwSize boxWidth = 5;

using std::numeric_limits;
using std::vector;
using std::min;
using std::max;

static int maxUnsuppressed(
    vector<bool>&suppressed,double*boxes,
    int nBoxes,vector<bool>&used)
{
    double max = -numeric_limits<double>::infinity();
    int maxIdx = -1;
    for(int iter = 0; iter < nBoxes; iter++)
    {
	double max_rp = *(boxes + nBoxes*4 + iter);
	if(max_rp >= max && !suppressed[iter] && !used[iter])
	{
	    max = max_rp;
	    maxIdx = iter;
	}
    }

    return maxIdx;
}

void trySuppressOther(
    double*boxes,mwSize nBoxes, int otherIdx, 
    double max_x1, double max_y1, double max_x2, double max_y2, double overlap,
    vector<bool>&suppressed)
{
    double other_x1 = *(boxes + nBoxes*0 + otherIdx);
    double other_y1 = *(boxes + nBoxes*1 + otherIdx);
    double other_x2 = *(boxes + nBoxes*2 + otherIdx);
    double other_y2 = *(boxes + nBoxes*3 + otherIdx);
    double other_rp = *(boxes + nBoxes*4 + otherIdx);	    
    double other_wd = other_x2 - other_x1 + 1;
    double other_hi = other_y2 - other_y1 + 1;
    double other_ar = other_wd*other_hi;

    // intersection
    double xx1 = max(other_x1,max_x1);
    double yy1 = max(other_y1,max_y1);
    double xx2 = min(other_x2,max_x2);
    double yy2 = min(other_y2,max_y2);
    double w = xx2-xx1+1;
    double h = yy2-yy1+1;
    
    // occlusion
    bool max_occ = isnan(max_x1);
    bool other_occ = isnan(other_x1);
    bool occCmpat = max_occ == other_occ;

    double o = w*h/other_ar;
    if(w > 0 && h > 0 && o > overlap && occCmpat)
    {
	// mexPrintf("nms_c.cc: suppressing %d\n",otherIdx);
	suppressed[otherIdx] = true;
	// mexPrintf("nms_c.cc: suppressed %d\n",otherIdx);
    }
}

/**
 *  MEX main...
 *  function res = nms(boxes,overlap)
 **/
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) { 
    // check arguments
    if (nrhs != 2)
	mexErrMsgTxt("Wrong number of inputs"); 
    if (nlhs != 1)
	mexErrMsgTxt("Wrong number of outputs");

    // get the input.
    double overlap = mxGetScalar(prhs[1]);
    double*boxes = mxGetPr(prhs[0]);
    mwSize nBoxes = mxGetM(prhs[0]);

    // do the computation.
    vector<bool> suppressed(nBoxes,false), used(nBoxes,false);
    int maxIter = 0;
    while(true)
    {
	maxIter++;
	// mexPrintf("nms_c.cc: maxIter = %d\n",maxIter);
	// find max...
	int maxIdx = maxUnsuppressed(suppressed,boxes,nBoxes,used);
	// mexPrintf("nms_c.cc: maxIdx = %d\n",maxIdx);
	if(maxIdx < 0)
	{
	    // mexPrintf("nms_c.cc: Breaking out of calcs\n");
	    break;
	}
	used[maxIdx] = true;
	// mexPrintf("nms_c.cc: starting next iteration!\n");

	// MATLAB data is columknwise, so incrementing by one moves us
	// down the current column (from row to row).
	double max_x1 = *(boxes + nBoxes*0 + maxIdx);
	double max_y1 = *(boxes + nBoxes*1 + maxIdx);
	double max_x2 = *(boxes + nBoxes*2 + maxIdx);
	double max_y2 = *(boxes + nBoxes*3 + maxIdx);
	double max_rp = *(boxes + nBoxes*4 + maxIdx);
	double max_wd = max_x2 - max_x1 + 1;
	double max_hi = max_y2 - max_y1 + 1;
	double max_ar = max_wd*max_hi;

	for(int otherIdx = 0; otherIdx < nBoxes; otherIdx++)
	{
	    trySuppressOther(
		boxes,nBoxes,  otherIdx, 
		 max_x1,  max_y1,  max_x2,  max_y2,  overlap,
		suppressed);
	}
    }
    // mexPrintf("nms_c.cc: calculations complete\n");

    // produce the output.
    // count the number of boxes which are used after NMS
    int outCt = 0;
    for(int iter = 0; iter < used.size(); iter++)
	if(used[iter])
	    outCt++;

    // mexPrintf("boxCt = %d\noutCt = %d\n",nBoxes,outCt);
    plhs[0] = mxCreateDoubleMatrix(outCt,boxWidth,mxREAL);
    double* out = mxGetPr(plhs[0]);
    for(int iter = 0, outIter = 0; iter < used.size(); iter++)
	if(used[iter])
	{
	    *(out + outCt*0 + outIter) = *(boxes + nBoxes*0 + iter);
	    *(out + outCt*1 + outIter) = *(boxes + nBoxes*1 + iter);
	    *(out + outCt*2 + outIter) = *(boxes + nBoxes*2 + iter);
	    *(out + outCt*3 + outIter) = *(boxes + nBoxes*3 + iter);
	    *(out + outCt*4 + outIter) = *(boxes + nBoxes*4 + iter);	    
	    outIter++;
	}
}

