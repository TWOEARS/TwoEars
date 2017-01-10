#include <memory>
#include <iostream>
#include <exception>

#include "../src/Processors/inputProc.hpp"
#include "matFiles.hpp"

using namespace openAFE;
using namespace std;

int main(int argc, char **argv) {
	
  vector<vector<double> > earSignals;
  double fsHz;
  
  double bufferSize_s = 10;
  bool doNormalize = false;
  uint32_t normalizeValue = MAXCODABLEVALUE;
  
  string dataPath;
  string outputName;
    
	  switch ( argc ) {
		  case 3:
			dataPath = argv[1];
			outputName = argv[2];
			break;
		  case 4:
			dataPath = argv[1];
			outputName = argv[2];
			bufferSize_s = atof(argv[3]);
			break;
		  case 5:
			dataPath = argv[1];
			outputName = argv[2];
			bufferSize_s = atof(argv[3]);
			doNormalize = *(argv[4]) != '0';
			break;
		  case 6:
			dataPath = argv[1];
			outputName = argv[2];
			bufferSize_s = atof(argv[3]);
			doNormalize = *(argv[4]) != '0';
			normalizeValue = atoi(argv[5]);
			break;		
		  default:
			cerr << "The correct usage is : ./TEST_input inFilePath outputName.mat bufferSize_s doNormalize normalizeValue" << endl;
			return 0;
	  }

  int result = matFiles::readMatFile(dataPath.c_str(), earSignals, &fsHz);
  
  if ( result == 0 ) {
	  shared_ptr <InputProc > inputSignal;
	  inputSignal.reset( new InputProc("input" /* name */, fsHz, bufferSize_s, doNormalize, normalizeValue ) );

	  inputSignal->processChunk ( earSignals[0].data(), earSignals[0].size(), earSignals[1].data(), earSignals[1].size() );
	  inputSignal->releaseChunk();
	  
	  shared_ptr<twoCTypeBlock<double> > lOut = inputSignal->getLeftWholeBufferAccessor();
	  shared_ptr<twoCTypeBlock<double> > rOut = inputSignal->getRightWholeBufferAccessor();
  
	  matFiles::writeTDSMatFile(outputName.c_str(), lOut, rOut, fsHz);
  }
  return 0;
}
