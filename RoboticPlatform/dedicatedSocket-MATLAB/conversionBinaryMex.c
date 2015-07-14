/*
 * arrayProduct.c - example in MATLAB External Interfaces
 *
 * Multiplies an input scalar (multiplier) 
 * times a 1xN matrix (inMatrix)
 * and outputs a 1xN matrix (outMatrix)
 *
 * The calling syntax is:
 *
 *		outMatrix = arrayProduct(multiplier, inMatrix)
 *
 * This is a MEX-file for MATLAB.
 */

#include <stdio.h>
#include "mex.h"
#include <matrix.h>
#include <stdint.h>

void conversionMex(double *inputStr, double *outputLeft, double *outputRight, double *output, int samples, int len)
{
    int32_t i, half;
    int32_t num, *p;
    char a[4];
    
    /*To calculate this one time and not on every loop*/
    half = len/2;
    
    for(i=0; i<samples; i++)
    {
        /*Left Sample*/
        /*Copy each of the 4 bytes to an array*/
        a[0] = (char) inputStr[i*4];
        a[1] = (char) inputStr[i*4+1];
        a[2] = (char) inputStr[i*4+2];
        a[3] = (char) inputStr[i*4+3];
        /*Pointer p points to array a*/
        p = (int32_t *) a;
        /*num equals the value p points to*/
        num = *p;
        /*Save the number in the output array*/
        outputLeft[i] = num;
        output[i] = num;
        
        /*Right Sample*/
        /*Copy each of the 4 bytes to an array*/
        a[0] = (char) inputStr[half + i*4];
        a[1] = (char) inputStr[half + i*4+1];
        a[2] = (char) inputStr[half + i*4+2];
        a[3] = (char) inputStr[half + i*4+3];
        /*Pointer p points to array a*/
        p = (int32_t *) a;
        /*num equals the value p points to*/
        num = *p;
        /*Save the number in the output array*/
        outputRight[i] = num;
        output[samples+i] = num;
    }
}

/* The gateway function */
void mexFunction(int nlhs, mxArray *plhs[],
                 int nrhs, const mxArray *prhs[])
{
    int32_t samples, i;
    size_t len;
    double *inputStr;
    double *outputLeft;
    double *outputRight;
    double *output;
    
    /* create a pointer to the real data in the input matrix  */
    inputStr = mxGetData(prhs[0]);

    len = mxGetNumberOfElements(prhs[0]); 
    samples = (len/4)/2;

    plhs[0] = mxCreateDoubleMatrix(samples,1,mxREAL);
    plhs[1] = mxCreateDoubleMatrix(samples,1,mxREAL);
    plhs[2] = mxCreateDoubleMatrix(samples, 2, mxREAL);

    outputLeft = mxGetPr(plhs[0]);
    outputRight = mxGetPr(plhs[1]);
    output =  mxGetPr(plhs[2]);
    
    /* call the computational routine */
    conversionMex(inputStr, outputLeft, outputRight, output, samples, len);
}