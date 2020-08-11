#include "mex.h"
#include <math.h>

void ripley(double *x, double *y, int np, int width, int height, double step, int msteps, double *rpc)
{
   int i, j, k, mxs;
   double dist, d1, d2, d3, d4, temp;  
   double get_weight(double, double, double, double, double);

   /* mexPrintf("The ripley k function is successfully called.\n"); */
   
   for(i=0; i<=msteps; i++)
	  rpc[i] = 0;

   /* step 1: for each particle, calculate the distance matrix */
   for(i=0; i<np; i++) {
      /* first, calculate four distances, d1, d2, d3, and d4 to the edges of study area */
	  d1 = y[i];
      d2 = x[i];
	  d3 = width - x[i];
      d4 = height - y[i];

	  /* remember: d3 > d1; d4 > d2; if otherwise need swapping */
	  /* this should be done outside the loop to reduce number of computations */
	  if(d3 < d1) {
		  temp = d1;
		  d1 = d3;
		  d3 = temp;
	  }

	  if(d4 < d2) {
		  temp = d2;
		  d2 = d4;
          d4 = temp;
      }

	  for(j=i+1; j<np; j++) {    /* j = i+1 means only 1/2 number of calculations than j=0 */
	     dist = sqrt(pow((x[i] - x[j]), 2) + pow((y[i] - y[j]), 2));  
	     
		 /* since a rectangular study area is concerned, we need to consider boundaries */
		 /* this is according to Goreaud et al J. Vet. Sci. 1999 */
		 /* determine the element to which the addition should be made */
	     mxs = ceil(dist / step); 

		 if(mxs <= msteps) {
	        temp = get_weight(dist, d1, d2, d3, d4);

			/*mexPrintf("\nweight = %.1f", temp);*/
		    rpc[mxs] = rpc[mxs] + temp;
		 }
      }
   }

   /*mexPrintf("\n");*/
  
   for(i=1; i<=msteps; i++)
	 rpc[i] = rpc[i] + rpc[i-1];

   for(i=0; i<=msteps; i++)
		/*rpc[i] = 2 * rpc[i] * width * height / (np * (np-1)); */
		/* rpc[i] = sqrt(2* rpc[i] * width * height / (3.14 * np *  (np-1))) - i * step; */
		
		/* this is the area normalized L(r)-r value */
		rpc[i] = 100 * (sqrt(rpc[i] / (3.14 * np )) - i * step);
		

   /* mxPrintf("The maximum distance is %.1f.\n", maxdist); */
	
   return;
}

/* function that calcualtes the weighting factor based on a rectangular study area */
double get_weight(double dist, double d1, double d2, double d3, double d4)
{
	double weight = 1;
	double aout, dist2, d12, d23;
	
	if(dist<=d1 && dist<=d2 && dist<=d3 && dist<=d4)   /* point is not near boundary */
		aout = 0;

	else if(dist>d1 && dist<=d2 && dist<=d3 && dist<=d4)
		aout = 2*acos(d1/dist);

	else {
		dist2 = pow(dist, 2);
		d12 = pow(d1, 2) + pow(d2, 2);
		d23 = pow(d2, 2) + pow(d3, 2);

		if(dist>d1 && dist>d2 && dist<=d3 && dist<=d4) {
			if(dist2 <= d12)
				aout = 2*acos(d1/dist) + 2*acos(d2/dist);
			else
				aout = 3.14/2 + acos(d1/dist) + acos(d2/dist);
		}

		else if(dist>d1 && dist>d3 && dist<=d2 && dist<=d4)
			aout = 2*acos(d1/dist) + 2*acos(d3/dist);

		else if(dist>d1 && dist>d2 && dist>d3 && dist<=d4) {
			if(dist2<=d12 && dist2<=d23)
				aout = 2*acos(d1/dist) + 2*acos(d2/dist) + 2*acos(d3/dist);
			else if(dist2<=d12 && dist2>d23)
				aout = 3.14/2 + 2*acos(d1/dist) + acos(d2/dist) + acos(d3/dist);
			else
				aout = 3.14 + acos(d1/dist) + acos(d3/dist);
		}
	}
	
	/*aout = acos(cos(aout));*/
	/*aout = floor(aout/6.28) * 6.28 + aout;*/
	
	if(aout < 0) {
		/*mexPrintf("\naout=%.1f", aout);*/
		aout = fmod(aout, 6.283) + 6.283;
		/*mexPrintf("\taout\'=%.1f", aout);*/
	}

	if(aout >= 6.283) {
		/*mexPrintf("\naout=%.1f", aout);*/
		aout = fmod(aout, 6.283);
		/*mexPrintf("\taout\'=%.1f", aout);*/
	}
	
	/*if(aout > 4.72)*/
	if(aout > 4.72)
		aout = 4.72;

	weight = 6.283 / (6.283 - aout);

	return weight;
}


/* entry point mex function */
void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[] )
{
   double *x, *y, step, *rpc;
   int width, height, msteps, np, npy;
   void ripley(double *, double *, int, int, int, double, int, double *);
   
   /* mexPrintf("Number of outputs: %d", nlhs); */
   
   /* check the correct number of inputs and outputs */
   if (nrhs != 6) {
       mexErrMsgTxt("Incorrect number of inputs (required: trace, k, l, m, p).");  }
   else if (nlhs > 1) {           /* do not use nlhs != 1 here since in command line nlhs = 0 */
       mexErrMsgTxt("Incorrect number of outputs (rquired: filtered)."); 
   }
   
   /* Assign pointers input trajectory array */
   x 	= mxGetPr(prhs[0]);
   np   = mxGetM(prhs[0]);      /* number of particles */
   y   	= mxGetPr(prhs[1]);      
   npy  = mxGetM(prhs[1]);
   
   /* read the other parameters (including k, l, m, and p) out */
   width  = *mxGetPr(prhs[2]);
   height = *mxGetPr(prhs[3]);
   step   = *mxGetPr(prhs[4]);
   msteps = *mxGetPr(prhs[5]);
   
   /* check the input 
   mexPrintf("\nThe parameters are width = %d, height = %d, step = %.2f, msteps = %d", width, height, step, msteps);
   mexPrintf("\nThe length of trajectory is %d and %d\n", np, npy);*/

   /* Allocate memory for output array */
   plhs[0] = mxCreateDoubleMatrix(msteps+1, 1, mxREAL);
    
   rpc = mxGetPr(plhs[0]);

   ripley(x, y, np, width, height, step, msteps, rpc);
}
