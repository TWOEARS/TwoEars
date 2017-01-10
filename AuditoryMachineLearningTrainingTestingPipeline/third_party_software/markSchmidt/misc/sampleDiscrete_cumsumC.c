#include <math.h>
#include "mex.h"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    int y,minY=1,maxY,nChoices,*i,nSamples,s;
    double *cs,*u;
    
    if (nrhs != 2)
        mexErrMsgTxt("Function needs two arguments: {cs,randomNumbers}");
    
    cs = mxGetPr(prhs[0]);
    u = mxGetPr(prhs[1]);
    
    nChoices = mxGetM(prhs[0]);
    if (nChoices < mxGetN(prhs[0]))
        nChoices = mxGetN(prhs[0]);
    
    nSamples = mxGetM(prhs[1]);
    if (nSamples < mxGetN(prhs[1]))
        nSamples = mxGetN(prhs[1]);
    
    plhs[0] = mxCreateNumericMatrix(mxGetM(prhs[1]),mxGetN(prhs[1]),mxINT32_CLASS,mxREAL);
    i = (int*)mxGetPr(plhs[0]);
    
    for(s = 0; s < nSamples; s++) {
        minY = 1;
        maxY = nChoices;
        while (1) {
            y = (minY+maxY)/2;
            
            if (cs[y-1] > u[s]) {
                if (y == 1 || cs[y-2] < u[s])
                    break;
                else
                    maxY = y-1;
            }
            else
                minY = y+1;
        }
        i[s] = y;
    }
}