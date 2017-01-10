#include "matFiles.hpp"
#include <iostream>

	int writeFs (MATFile *pmat, mxArray *pn, double fsHz) {
		/* fsHZ */
		pn = mxCreateDoubleScalar(fsHz);
		   if (pn == NULL) {
				printf("Unable to create mxArray with mxCreateDoubleMatrix\n");
				return(1);
		}
		  
		int status = matPutVariable(pmat, "fsHz", pn);
		 if ((status) != 0) {
			  printf("Error writing.\n");
			  return(EXIT_FAILURE);
		  }
		return 0;  	
		
	}
	
	int matFiles::readMatFile(const char *file, std::vector <std::vector<double> >& earSignals, double *fsHz) {
	  MATFile *pmat;
	  const char **dir;
	  const char *name;
	  int	  ndir;
	  int	  i;
	  mxArray *pa;
	  mxArray *var;
	  const size_t *dims;
	  size_t ndims;
	  double *data;
		
	  /*
	   * Open file to get directory
	   */
	  pmat = matOpen(file, "r");
	  if (pmat == NULL) {
		printf("Error opening file %s\n", file);
		return(1);
	  }
	  
	  /*
	   * get directory of MAT-file
	   */
	  dir = (const char **)matGetDir(pmat, &ndir);
	  if (dir == NULL) {
		printf("Error reading directory of file %s\n", file);
		return(1);
	  }
	  mxFree(dir);

	  /* In order to use matGetNextXXX correctly, reopen file to read in headers. */
	  if (matClose(pmat) != 0) {
		printf("Error closing file %s\n",file);
		return(1);
	  }
	  pmat = matOpen(file, "r");
	  if (pmat == NULL) {
		printf("Error reopening file %s\n", file);
		return(1);
	  }

	  /* Get headers of all variables */
	  /* Examining the header for each variable */
	  for (i=0; i < ndir; i++) {
		pa = matGetNextVariableInfo(pmat, &name);
		var = matGetVariable(pmat, name);
		data = mxGetPr(var);
		
		if (pa == NULL) {
		printf("Error reading in file %s\n", file);
		return(1);
		}

		if ( strcmp(name,"earSignals") == 0 )  {
			ndims = mxGetNumberOfDimensions(pa);
			dims = mxGetDimensions(pa);
			
			earSignals.resize(ndims);
			
			for ( size_t ii = 0 ; ii < ndims ; ++ii )
				earSignals[ii].resize(dims[0],0);
				
			size_t ii, iii;
			for ( ii = 0 ; ii < dims[0] ; ++ii )
				earSignals[0][ii] =  data[ii];

			for ( ii = dims[0], iii = 0 ; ii < dims[0] * 2 ; ++ii, ++iii )
				earSignals[1][iii] =  data[ii];
				
		} else	if ( strcmp(name,"fsHz") == 0 ) {
			ndims = mxGetNumberOfDimensions(pa);
			dims = mxGetDimensions(pa);
			
			assert( ndims == 2 );
			assert( dims[0] == 1 );
							
			*fsHz = data[0];
		}
			
		mxDestroyArray(pa);
	  }

	  if (matClose(pmat) != 0) {
		  printf("Error closing file %s\n",file);
		  return(1);
	  }
	  return(0);
	}

	int matFiles::writeTDSMatFile(const char *file, std::shared_ptr<openAFE::twoCTypeBlock<double> > left, std::shared_ptr<openAFE::twoCTypeBlock<double> > right, double fsHz) {
		
		MATFile *pmat;

		/* Variables for mxArrays  */
		mxArray *pn_l = NULL, *pn2 = NULL;

		pmat = matOpen(file, "w");
		if (pmat == NULL) {
		  printf("Error creating file");
		return(EXIT_FAILURE);
		}
		int status;
		/* EAR SIGNAL */
		uint32_t leftSize = left->array1.second + left->array2.second;
		uint32_t rightSize = right->array1.second + right->array2.second;
		
		assert ( leftSize == rightSize );
		
		pn_l = mxCreateDoubleMatrix(leftSize,2,mxREAL);
		   if (pn_l == NULL) {
				printf("Unable to create mxArray with mxCreateDoubleMatrix\n");
				return(1);
		}

		/* Left */
		memcpy( mxGetPr(pn_l), left->array1.first, left->array1.second * sizeof(double) );
		memcpy( mxGetPr(pn_l) + left->array1.second, left->array2.first, left->array2.second * sizeof(double) );

		/* Right */
		memcpy( mxGetPr(pn_l) + leftSize, right->array1.first, right->array1.second * sizeof(double) );
		memcpy( mxGetPr(pn_l) + leftSize + right->array1.second, right->array2.first, right->array2.second * sizeof(double) );
								
		status = matPutVariable(pmat, "outputSignals", pn_l);
		if ((status) != 0) {
			printf("Error writing.\n");
			return(EXIT_FAILURE);
		}
				
		/* fsHZ */
		writeFs (pmat, pn2, fsHz);
		return(0);			  
	}

	int matFiles::writeTFSMatFile(const char *file, std::vector<std::shared_ptr<openAFE::twoCTypeBlock<double> > >& left, std::vector<std::shared_ptr<openAFE::twoCTypeBlock<double> > >& right, double fsHz) {

		MATFile *pmat;

		/* Variables for mxArrays  */
		mxArray *pn_l = NULL, *pn_r = NULL, *pn2 = NULL;

		pmat = matOpen(file, "w");
		if (pmat == NULL) {
		  printf("Error creating file");
		return(EXIT_FAILURE);
		}
		int status;

		/* EAR SIGNAL */
		std::size_t leftSize = left.size();
		std::size_t rightSize = right.size();
		
		uint32_t frameNumber = left[0]->array1.second + left[0]->array2.second;
		
		assert ( leftSize == rightSize );
		
		pn_l = mxCreateDoubleMatrix(frameNumber,leftSize,mxREAL);
		   if (pn_l == NULL) {
				printf("Unable to create mxArray with mxCreateDoubleMatrix\n");
				return(1);
		}

		for ( std::size_t ii = 0 ; ii < leftSize ; ++ii ) {	
			memcpy( mxGetPr(pn_l) + frameNumber * ii, left[ii]->array1.first, left[ii]->array1.second * sizeof(double) );
			memcpy( mxGetPr(pn_l) + frameNumber * ii + left[ii]->array1.second, left[ii]->array2.first, left[ii]->array2.second * sizeof(double) );
		}
							
		status = matPutVariable(pmat, "leftOutput", pn_l);
		if ((status) != 0) {
			printf("Error writing.\n");
			return(EXIT_FAILURE);
		}


		pn_r = mxCreateDoubleMatrix(frameNumber,rightSize,mxREAL);
		   if ( pn_r == NULL ) {
				printf("Unable to create mxArray with mxCreateDoubleMatrix\n");
				return(1);
		}

		for ( std::size_t ii = 0 ; ii < rightSize ; ++ii ) {	
			memcpy( mxGetPr(pn_r) + frameNumber * ii, right[ii]->array1.first, right[ii]->array1.second * sizeof(double) );
			memcpy( mxGetPr(pn_r) + frameNumber * ii + right[ii]->array1.second, right[ii]->array2.first, right[ii]->array2.second * sizeof(double) );
		}
								
		status = matPutVariable(pmat, "rightOutput", pn_r);
		if ((status) != 0) {
			printf("Error writing.\n");
			return(EXIT_FAILURE);
		}
	
		/* fsHZ */
		writeFs (pmat, pn2, fsHz);
		return(0);		
	}

	int matFiles::writeXCORRMatFile(const char *file, std::vector<std::vector<std::shared_ptr<openAFE::twoCTypeBlock<double> > > >& left, double fsHz) {
		MATFile *pmat;

		/* Variables for mxArrays */
		mxArray *pn_l = NULL, *pn2 = NULL;
		
		pmat = matOpen(file, "w");
		if (pmat == NULL) {
		  printf("Error creating file");
		return(EXIT_FAILURE);
		}

		int status;

		/* EAR SIGNAL */
		std::size_t leftChannels = left.size();

		std::size_t leftLags = left[0].size();
				
		uint32_t frameNumber = left[0][0]->array1.second + left[0][0]->array2.second;		

		std::size_t  ndim = 3, dims[3] = {frameNumber, leftChannels, leftLags };

		pn_l = mxCreateNumericArray(ndim, dims, mxDOUBLE_CLASS, mxREAL );
		   if (pn_l == NULL) {
				printf("Unable to create mxArray with mxCreateDoubleMatrix\n");
				return(1);
		}
	
		for ( std::size_t ii = 0 ; ii < leftChannels ; ++ii ) {
			for ( std::size_t jj = 0 ; jj < leftLags ; ++jj ) {	
				memcpy( mxGetPr(pn_l) + frameNumber * ii + frameNumber * leftChannels * jj , left[ii][jj]->array1.first, left[ii][jj]->array1.second * sizeof(double) );
				memcpy( mxGetPr(pn_l) + frameNumber * ii + frameNumber * leftChannels * jj + left[ii][jj]->array1.second, left[ii][jj]->array2.first, left[ii][jj]->array2.second * sizeof(double) );
			}
		}
		
		status = matPutVariable(pmat, "leftOutput", pn_l);
		if ((status) != 0) {
			printf("Error writing.\n");
			return(EXIT_FAILURE);
		}

		writeFs (pmat, pn2, fsHz);
		return(0);			
	}
