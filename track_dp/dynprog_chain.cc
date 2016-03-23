// JSS3 - 2012-6-21 
#include "mex.h"
#include "matrix.h"
#include "../mex/compat.h"
#include <limits>
#include <math.h>
#include <vector>

using std::numeric_limits;
using std::max;
using std::min;

// Undocumented Features!
extern "C" int mxUnshareArray(mxArray *pa, int level);
extern "C" int mxIsSharedArray(mxArray* pa);
extern "C" mxArray *mxCreateSharedDataCopy(const mxArray *pr);

#define OCCLUDED isnan
#define INF (numeric_limits<double>::infinity())

#ifndef round(x)
    #define round(x) (x<0?ceil((x)-0.5):floor((x)+0.5))
#endif

static double rect_overlap(double newX1, double newY1, double newX2, double newY2, 
			   double oldX1, double oldY1, double oldX2, double oldY2)
{
    // intersection
    double 
	int_x1 = max(newX1,oldX1),
	int_y1 = max(newY1,oldY1),
	int_x2 = min(newX2,oldX2),
	int_y2 = min(newY2,oldY2);
    double 
	int_w  = int_x2 - int_x1 + 1,
	int_h  = int_y2 - int_y1 + 1;
    double int_ar = int_w*int_h;
    
    // area new
    double 
	new_w = newX2 - newX1 + 1,
	new_h = newY2 - newY1 + 1;
    double new_ar= new_w*new_h;

    // area old
    double 
	old_w = oldX2 - oldX1 + 1,
	old_h = oldY2 - oldY1 + 1;
    double old_ar= old_w*old_h;

    if(int_w <= 0 || int_h <= 0)
	return -1;
    else
	return int_ar/(new_ar+old_ar-int_ar);
}

static double cost_pw_corner(double newX1, double newY1, double newX2, double newY2, 
			     double oldX1, double oldY1, double oldX2, double oldY2)
{
    double cost;
    if(!OCCLUDED(newX1) && !OCCLUDED(oldX1)) 
    {
	// neither is occluded
	double cost_tl = (newX1-oldX1)*(newX1-oldX1)+(newY1-oldY1)*(newY1-oldY1);
	double cost_br = (newX2-oldX2)*(newX2-oldX2)+(newY2-oldY2)*(newY2-oldY2);
	cost = (cost_tl+cost_br)/2;
    }
    else
    {
	cost = 0.0;
    }	
    return cost;
}

static double cost_pw_infi(double newX1, double newY1, double newX2, double newY2, 
			   double newOcc, double newEmg,
			   double oldX1, double oldY1, double oldX2, double oldY2,
			   double oldOcc, double oldEmg)
{
    int dp_min_time_occluded = 25;
    int oldTime = round(oldY2);
    int newTime = round(newY2);

    if(!OCCLUDED(newX1) && OCCLUDED(oldX1))
    {
	// leaving occlusion
	if(oldTime >= dp_min_time_occluded && newEmg > .5)
	    return 0;
	else
	    return INF;
    }
    else if(OCCLUDED(newX1) && !OCCLUDED(oldX1))
    {
	// moving into occlusion
	if(newTime == 0 && oldOcc > .5)
	    return 0;
	else
	    return INF;
    }
    else if(OCCLUDED(oldX1))
    {
	// staying in occlusion
	if(oldTime + 1 == newTime || (newTime == oldTime && newTime >= dp_min_time_occluded))
	    return 0.0;
	else
	    return INF;
    }
    else
    {
	// staying visible
	//double maxDist = 25;
	//double cost_pw = sqrt(cost_pw_corner(newX1, newY1, newX2, newY2, 
	//				     oldX1, oldY1, oldX2, oldY2));
        //if(cost_pw > maxDist)
        //	    return INF;
        //	else
        //	  return 0.0;

	double o = rect_overlap(newX1, newY1, newX2, newY2, 
				oldX1, oldY1, oldX2, oldY2);
	if(o > .25)
	    return 0.0;
	else
	    return INF;
    }
}

static void do_dynprog_chain(int newStates_count,int oldStates_count,
			     double*new_states,uint32_t*bps,
			     double*old_states,double*new_dets,double*projRects)
{
    // relax each edge
    for(int newIter = 0; newIter < newStates_count; newIter++)
    {
	// extract the new state
	double newX1 = *(new_states + newStates_count*0 + newIter);
	double newY1 = *(new_states + newStates_count*1 + newIter);
	double newX2 = *(new_states + newStates_count*2 + newIter);
	double newY2 = *(new_states + newStates_count*3 + newIter);
	double newCost = *(new_states + newStates_count*4 + newIter);
	// extract the corresponding detection
	double detX1 = *(new_dets + newStates_count*0 + newIter);
	double detY1 = *(new_dets + newStates_count*1 + newIter);
	double detX2 = *(new_dets + newStates_count*2 + newIter);
	double detY2 = *(new_dets + newStates_count*3 + newIter);
	double detResp = *(new_dets + newStates_count*4 + newIter);
	double detOcc = *(new_dets + newStates_count*5 + newIter);
	double detEmg = *(new_dets + newStates_count*6 + newIter);
	// extract the back pointer
	uint32_t*backPtr = &bps[newIter];

	for(int oldIter = 0; oldIter < oldStates_count; oldIter++)
	{
	    // extract the old state
	    double oldX1 = *(old_states + oldStates_count*0 + oldIter);
	    double oldY1 = *(old_states + oldStates_count*1 + oldIter);
	    double oldX2 = *(old_states + oldStates_count*2 + oldIter);
	    double oldY2 = *(old_states + oldStates_count*3 + oldIter);
	    double oldCost = *(old_states + oldStates_count*4 + oldIter);
	    double oldOcc = *(old_states + oldStates_count*5 + oldIter);
	    double oldEmg = *(old_states + oldStates_count*6 + oldIter);
	    if(isnan(oldCost))
		continue;
	    // extract the old LK Projection
	    double projX1 = *(projRects + (oldStates_count)*0 + oldIter);
	    double projY1 = *(projRects + (oldStates_count)*1 + oldIter);
	    double projX2 = *(projRects + (oldStates_count)*2 + oldIter);
	    double projY2 = *(projRects + (oldStates_count)*3 + oldIter);

	    // compute the cost
	    double lcl_cost = -detResp;
	    //double corner_cost = cost_pw_corner(detX1, detY1, detX2, detY2,
	    //			  projX1, projY1, projX2, projY2);
	    double pw_cost = cost_pw_infi(detX1, detY1, detX2, detY2, detOcc, detEmg,
					  projX1, projY1, projX2, projY2, oldOcc, oldEmg);
	    double cost = lcl_cost + pw_cost + oldCost;

	    // relax
	    if(cost <= newCost)
	    {
		//mexPrintf("allowing connection from: %f %f %f %f\n",oldX1,oldY1,oldX2,oldY2);
		//mexPrintf("\t to: %f %f %f %f\n",detX1,detY1,detX2,detY2);
		//mexPrintf("\tcorner_cost = %f\n",corner_cost);
		//mexPrintf("\t pwCost = %f\n",pw_cost);
		newCost = *(new_states + newStates_count*4 + newIter) = cost;
		*backPtr = (uint32_t)(oldIter+1);
	    }
	}
    }
}

// do dynamic programming on a markov chain.
// [states,bp] = dynprog_chain(states,projRects,new_detections);
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) 
{
  // check arguments
  if (nrhs != 3)
    mexErrMsgTxt("usage: [states,bp] = dynprog_chain(states,oldRects,new_detections)"); 
  if (nlhs != 2)
    mexErrMsgTxt("usage: [states,bp] = dynprog_chain(states,oldRects,new_detections)");
  if (mxIsDouble(prhs[0])  == false) mexErrMsgTxt("states is not double.");
  if (mxIsDouble(prhs[1])  == false) mexErrMsgTxt("projRects is not double.");
  if (mxIsDouble(prhs[2])  == false) mexErrMsgTxt("new_detections is not double.");

  // get sizes
  mwSize newStates_count = mxGetM(prhs[2]);
  mwSize oldStates_count = mxGetM(prhs[0]);

  // init the output matrices
  plhs[0] = mxCreateDoubleMatrix(newStates_count,5,mxREAL);      
  plhs[1] = mxCreateNumericMatrix(newStates_count,1,mxUINT32_CLASS,mxREAL);

  // get out ptrs 
  double  *new_states = mxGetPr(plhs[0]); // 5 column
  uint32_t*bps = (uint32_t*)mxGetData(plhs[1]);
  // get in ptrs
  double  *old_states = mxGetPr(prhs[0]); // 5 column
  double  *new_dets   = mxGetPr(prhs[2]); // 5 column
  double  *projRects  = mxGetPr(prhs[1]); // 4 column

  // init the outputs to defautl values
  for(int newIter = 0; newIter < newStates_count; newIter++)
  {
      *(new_states + newStates_count*0 + newIter) = *(new_dets + newStates_count*0 + newIter);
      *(new_states + newStates_count*1 + newIter) = *(new_dets + newStates_count*1 + newIter);
      *(new_states + newStates_count*2 + newIter) = *(new_dets + newStates_count*2 + newIter);
      *(new_states + newStates_count*3 + newIter) = *(new_dets + newStates_count*3 + newIter);
      *(new_states + newStates_count*4 + newIter) = INF;
  }
  for(int bIter = 0; bIter < newStates_count; bIter++)
      bps[bIter] = 0;

  // now we can actually do some dynamic programming?
  do_dynprog_chain(newStates_count,oldStates_count,
		   new_states,bps,
		   old_states,new_dets,projRects);
}

