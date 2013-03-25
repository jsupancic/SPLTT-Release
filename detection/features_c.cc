#include <math.h>
#include "mex.h"

// small value, used to avoid division by zero
#define eps 0.0001

// Number of Orientation bins
const int ORI_BINS = 18;

// unit vectors used to compute gradient orientation
double uu[ORI_BINS] = 
  {
    1.0000,
    0.9397,
    0.7660,
    0.5000,
    0.1736,
    -0.1736,
    -0.5000,
    -0.7660,
    -0.9397,
    -1.0000,
    -0.9397,
    -0.7660,
    -0.5000,
    -0.1736,
    0.1736,
    0.5000,
    0.7660,
    0.9397
  };

double vv[ORI_BINS] = 
  {
    0,
    0.3420,
    0.6428,
    0.8660,
    0.9848,
    0.9848,
    0.8660,
    0.6428,
    0.3420,
    0,
    -0.3420,
    -0.6428,
    -0.8660,
    -0.9848,
    -0.9848,
    -0.8660,
    -0.6428,
    -0.3420
  };

static inline double min(double x, double y) { return (x <= y ? x : y); }

#define FEAT_HOG 1
#define FEAT_COL 2

double* process_build_HOG_hist(int*visible,double*im,const int *dims,int sbin, int*blocks)
{
  double *hist = (double *)mxCalloc(blocks[0]*blocks[1]*ORI_BINS, sizeof(double));

  for (int x = 1; x < visible[1]-1; x++) {
    for (int y = 1; y < visible[0]-1; y++) {
      // first color channel
      double *s = im + x*dims[0] + y;
      double dy = *(s+1) - *(s-1);
      double dx = *(s+dims[0]) - *(s-dims[0]);
      double v = dx*dx + dy*dy;

      // second color channel
      s += dims[0]*dims[1];
      double dy2 = *(s+1) - *(s-1);
      double dx2 = *(s+dims[0]) - *(s-dims[0]);
      double v2 = dx2*dx2 + dy2*dy2;

      // third color channel
      s += dims[0]*dims[1];
      double dy3 = *(s+1) - *(s-1);
      double dx3 = *(s+dims[0]) - *(s-dims[0]);
      double v3 = dx3*dx3 + dy3*dy3;

      // pick channel with strongest gradient
      if (v2 > v) {
	v = v2;
	dx = dx2;
	dy = dy2;
      } 
      if (v3 > v) {
	v = v3;
	dx = dx3;
	dy = dy3;
      }

      // snap to one of ORI_BINS orientations
      double best_dot = 0;
      int best_o = 0;
      for (int o = 0; o < ORI_BINS; o++) {
	//double dot = fabs(uu[o]*dx + vv[o]*dy);
	double dot = uu[o]*dx + vv[o]*dy;
	if (dot > best_dot) {
	  best_dot = dot;
	  best_o = o;
	}
      }
      
      // add to 4 histograms around pixel using linear interpolation
      double xp = ((double)x+0.5)/(double)sbin - 0.5F;
      double yp = ((double)y+0.5)/(double)sbin - 0.5F;
      int ixp = (int)floor(xp);
      int iyp = (int)floor(yp);
      double vx0 = xp-ixp;
      double vy0 = yp-iyp;
      double vx1 = 1.0-vx0;
      double vy1 = 1.0-vy0;      
      v = sqrt(v);
      
      if (ixp >= 0 && iyp >= 0) {
	*(hist + ixp*blocks[0] + iyp + best_o*blocks[0]*blocks[1]) += 
	  vx1*vy1*v;
      }
      
      if (ixp+1 < blocks[1] && iyp >= 0) {
	*(hist + (ixp+1)*blocks[0] + iyp + best_o*blocks[0]*blocks[1]) += 
	  vx0*vy1*v;
      }

      if (ixp >= 0 && iyp+1 < blocks[0]) {
	*(hist + ixp*blocks[0] + (iyp+1) + best_o*blocks[0]*blocks[1]) += 
	  vx1*vy0*v;
      }
      
      if (ixp+1 < blocks[1] && iyp+1 < blocks[0]) {
	*(hist + (ixp+1)*blocks[0] + (iyp+1) + best_o*blocks[0]*blocks[1]) += 
	  vx0*vy0*v;
      }
    }
  }

  return hist;
}

void process_normalize_HOG(double *hist, int*blocks, double *norm, int*out, double *feat)
{
  // compute energy in each block by summing over orientations
  for (int o = 0; o < ORI_BINS; o++) {
    double *src = hist + o*blocks[0]*blocks[1];
    double *dst = norm;
    double *end = dst + blocks[1]*blocks[0];
    while (dst < end) {
      *(dst++) += (*src) * (*src);
      src++;
    }
  }

  // compute normalized values
  for (int x = 0; x < out[1]; x++) {
    for (int y = 0; y < out[0]; y++) {
      double *dst = feat + x*out[0] + y;      
      double *src, *p, n1, n2, n3, n4;

      p = norm + (x+1)*blocks[0] + y+1;
      n1 = 1.0 / sqrt(*p + *(p+1) + *(p+blocks[0]) + *(p+blocks[0]+1) + eps);
      p = norm + (x+1)*blocks[0] + y;
      n2 = 1.0 / sqrt(*p + *(p+1) + *(p+blocks[0]) + *(p+blocks[0]+1) + eps);
      p = norm + x*blocks[0] + y+1;
      n3 = 1.0 / sqrt(*p + *(p+1) + *(p+blocks[0]) + *(p+blocks[0]+1) + eps);
      p = norm + x*blocks[0] + y;      
      n4 = 1.0 / sqrt(*p + *(p+1) + *(p+blocks[0]) + *(p+blocks[0]+1) + eps);

      double t1 = 0;
      double t2 = 0;
      double t3 = 0;
      double t4 = 0;

      src = hist + (x+1)*blocks[0] + (y+1);
      for (int o = 0; o < ORI_BINS; o++) {
	double h1 = min(*src * n1, 0.2);
	double h2 = min(*src * n2, 0.2);
	double h3 = min(*src * n3, 0.2);
	double h4 = min(*src * n4, 0.2);
	*dst = 0.5 * (h1 + h2 + h3 + h4);
	t1 += h1;
	t2 += h2;
	t3 += h3;
	t4 += h4;
	dst += out[0]*out[1];
	src += blocks[0]*blocks[1];
      }

      *dst = 0.2357 * t1;
      dst += out[0]*out[1];
      *dst = 0.2357 * t2;
      dst += out[0]*out[1];
      *dst = 0.2357 * t3;
      dst += out[0]*out[1];
      *dst = 0.2357 * t4;
    }
  }
}

/**
 * JSS3 sigmoid function S
 **/
double sigmoid(double x)
{
    return 1./(1+exp(-x));
}

/**
 * JSS3 function to compute chromatic (RGB) averages.
 **/
void process_chromatics(double*im,int*visible,
			const int *imDims/*like dims*/,
			double *feat/*like out*/,
			int*featDims,int sbin, int*blocks, int base)
{
    double rSum = 0, gSum = 0, bSum = 0;

    // sum the colors
    for (int x = 1; x < visible[1]-1; x++) 
    {
	for (int y = 1; y < visible[0]-1; y++) 
	{  
	    // what bin corresponds tho this pixel?
	    double xbinf = ((double)x+0.5)/(double)sbin - 0.5F;
	    double ybinf = ((double)y+0.5)/(double)sbin - 0.5F;
	    int binX = (int)floor(xbinf);
	    int binY = (int)floor(ybinf);

	    // get RGB
	    double*pixelPtr = im + x*imDims[0] + y;
	    double r = *pixelPtr;
	    pixelPtr += imDims[0] * imDims[1];
	    double g = *pixelPtr;
	    pixelPtr += imDims[0] * imDims[1];
	    double b = *pixelPtr;

	    // hist is RxC
	    // feat is (R-2)x(C-2)
	    binX--;
	    binY--;
	    if(binX < 0 || binY < 0 || binX >= featDims[1] || binY >= featDims[0])
	       continue;

	    // add to the bin...
	    if(!(binX < featDims[1]) || !(binY < featDims[0]) || 
		binX < 0 || binY < 0)
	    {
		mexPrintf("binY = %d\n",binY);
		mexPrintf("binX = %d\n",binX);
		mexPrintf("featDims[0] = %d\n",featDims[0]);
		mexPrintf("featDims[1] = %d\n",featDims[1]);
		mexPrintf("imDims[0] = %d\n",imDims[0]);
		mexPrintf("imDims[1] = %d\n",imDims[1]);
		mexPrintf("blocks[0] = %d\n",blocks[0]);
		mexPrintf("blocks[1] = %d\n",blocks[1]);
		mexErrMsgTxt("features: bad chromatic bin detected!");		
	    }
	    
	    double *bin = feat + binX*featDims[0] + binY;
	    bin += (base)*(featDims[0] * featDims[1]);
	    *bin += r;
	    rSum += r;
	    bin += featDims[0] * featDims[1];
	    *bin += g;
	    gSum += g;
	    bin += featDims[0] * featDims[1];
	    *bin += b;
	    bSum += b;
	}
    }

    // normalize
    for (int binX = 0; binX < featDims[1]; binX++) 
    {
	for (int binY = 0; binY < featDims[0]; binY++) 
	{ 
	    static const double COL_NORM_FACT = 15625; //25*381625; //

	    double *bin = feat + binX*featDims[0] + binY;
	    bin += (base)*(featDims[0] * featDims[1]);
	    //*bin /=   COL_NORM_FACT; //
	    *bin /= 25*rSum;
	    //*bin = sigmoid(*bin/(sbin*sbin*255.f)-.5)-.5;
	    bin += featDims[0] * featDims[1];
	    //*bin /=   COL_NORM_FACT; //25*gSum;
	    *bin /= 25*gSum;
	    //*bin = sigmoid(*bin/(sbin*sbin*255.f)-.5)-.5;
	    bin += featDims[0] * featDims[1];
	    //*bin /=   COL_NORM_FACT; //25*bSum;
	    *bin /= 25*bSum;
	    //*bin = sigmoid(*bin/(sbin*sbin*255.f)-.5)-.5;
	}
    }   
}

// main function:
// takes a double color image and a bin size 
// returns HOG features
mxArray *process(const mxArray *mximage, const mxArray *mxsbin, int featType) {
  double *im = (double *)mxGetPr(mximage);
  const int *dims = mxGetDimensions(mximage);
  if (mxGetNumberOfDimensions(mximage) != 3)
    mexErrMsgTxt("Invalid input: mxGetNumberOfDimensions(mximage) != 3");
  if (dims[2] != 3)
    mexErrMsgTxt("Invalid input: dims[2] != 3");
  if (mxGetClassID(mximage) != mxDOUBLE_CLASS)  
    mexErrMsgTxt("Invalid input: mxGetClassID(mximage) != mxDOUBLE_CLASS");      

  int sbin = (int)mxGetScalar(mxsbin);

  // memory for caching orientation histograms & their norms
  int blocks[2];
  blocks[0] = dims[0]/sbin;
  blocks[1] = dims[1]/sbin;
  double *norm = (double *)mxCalloc(blocks[0]*blocks[1], sizeof(double));

  // memory for HOG features
  int out[3];
  out[0] = blocks[0]-2;
  out[1] = blocks[1]-2;
  out[2] = 0;
  if(featType & FEAT_HOG)
    out[2] += ORI_BINS + 4;
  if(featType & FEAT_COL)
    out[2] += 3;
  mxArray *mxfeat = mxCreateNumericArray(3, out, mxDOUBLE_CLASS, mxREAL);
  double *feat = (double *)mxGetPr(mxfeat);
  
  int visible[2];
  visible[0] = blocks[0]*sbin;
  visible[1] = blocks[1]*sbin;
  
  // loop over all pixels in the cell to compute the HOG histogram
  double *hist = process_build_HOG_hist(visible,im,dims,sbin, blocks);

  // normalize the cells in the HOG histogram
  int base = 0;
  if(featType & FEAT_HOG)
  {
      process_normalize_HOG(hist, blocks, norm, out, feat);
      base += ORI_BINS+4;
  }

  // compute the chromatic features
  if(featType & FEAT_COL)
    process_chromatics(im,visible,dims,feat,out,sbin,blocks,base);

  mxFree(hist);
  mxFree(norm);
  return mxfeat;
}

// matlab entry point
// F = features(image, bin, featureType)
// image should be color with double values
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) { 
  if (nrhs < 2)
    mexErrMsgTxt("Wrong number of inputs"); 
  if (nlhs != 1)
    mexErrMsgTxt("Wrong number of outputs");

  // get the features we are to compute
  int featType = FEAT_HOG;
  if(nrhs >= 3)
    featType = (int)mxGetScalar(prhs[2]);

  plhs[0] = process(prhs[0], prhs[1], featType);
}


/* Equivalent MATLAB code
function feat = features(im,sbin)
% res = features(im,sbin)
% let [imy,imx] = size(impatch)
% res will be (imy/8-1) by (imx/8-1) by (4+9)
% where there are 9 orientation bins, and 4 normalizations 
% for every 8x8 pixel-block

% Crop/pad image to make it a multiple of sbin
[ty,tx,tz] = size(im);
imy = round(ty/sbin)*sbin;
if imy > ty,
  im = padarray(im,[imy-ty 0 0],'post');
elseif imy < ty,
  im = im(1:imy,:,:);
end
imx = round(tx/sbin)*sbin;
if imx > tx,
  im = padarray(im,[0 imx-tx 0],'post');
elseif imx < tx,
  im = im(:,1:imx,:);
end

im = double(im);
n = (imy-2)*(imx-2);

%Pick the strongest gradient across color channels
dy = im(3:end,2:end-1,:) - im(1:end-2,2:end-1,:); dy = reshape(dy,n,3); 
dx = im(2:end-1,3:end,:) - im(2:end-1,1:end-2,:); dx = reshape(dx,n,3);
len = dx.^2 + dy.^2;
[len,I] = max(len,[],2);
len = sqrt(len);
I = sub2ind([n 3],[1:n]',I);
dy = dy(I); dx = dx(I);

%Snap to an orientation
[uu,vv] = pol2cart([0:pi/9:pi-.01],1);
v = dy./(len+eps); u = dx./(len+eps);
[dummy,I] = max(abs(u(:)*uu + v(:)*vv),[],2);

%Bin spatially
ssiz = [imy imx]/sbin;
feat = zeros(prod(ssiz), 9);
for i = 1:9,
  %Generate sparse map
  tmp = reshape(len.*(I == i),imy-2,imx-2);
  tmp = padarray(tmp,[1 1]);
  feat(:,i) = sum(im2col(tmp,[sbin sbin],'distinct'))';
end

indMask = reshape(1:prod(ssiz),ssiz);
indMask = im2col(indMask,[2 2])';
n = size(indMask,1);
feat = reshape(feat(indMask,:),n,4*9);

%Normalize and clip to .2
nn = sqrt(sum(feat.^2,2)) + eps;
feat = feat./repmat(nn,1,4*9);
feat = min(feat,.2);

%Take projections along orientations and normalization directions
feat = reshape(feat,[n 4 9]);
feat = [.5*reshape(sum(feat,2),[n 9]) .2357*sum(feat,3)];
feat = reshape(feat,[ssiz-1 (4+9)]);
*/



