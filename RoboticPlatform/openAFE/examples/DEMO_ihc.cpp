#include <memory>
#include <iostream>

#include "../src/Processors/inputProc.hpp"
#include "../src/Processors/preProc.hpp"
#include "../src/Processors/gammatoneProc.hpp"
#include "../src/Processors/ihcProc.hpp"

#include "matFiles.hpp"

using namespace openAFE;
using namespace std;

int main(int argc, char **argv) {

  vector<vector<double> > earSignals;
  double fsHz;
  
  string dataPath;  
  string outputName; 
  
  ihcMethod method = _dau;

  switch ( argc ) {
	case 3:
		dataPath = argv[1];
		outputName = argv[2];
	break;
	case 4:  
		dataPath = argv[1];
		outputName = argv[2];
		if ( strcmp("none", argv[3]) == 0 ) method = _none;
		else if ( strcmp("halfwave", argv[3]) == 0 ) method = _halfwave;
		else if ( strcmp("fullwave", argv[3]) == 0 ) method = _fullwave;
		else if ( strcmp("square", argv[3]) == 0 ) method = _square;
		else if ( strcmp("dau", argv[3]) == 0 ) method = _dau;
		else { cerr << "Available flags are : none, halfwave, fullwave, square, dau" << endl;
			   return 0;
			 }
		break;
	default:
		cerr << "The correct usage is : ./TEST_ihc inFilePath outputName ihc_method" << endl;
		return 0;
	}  
  
  int result = matFiles::readMatFile(dataPath.c_str(), earSignals, &fsHz);

  if ( result == 0 ) {
	  shared_ptr <InputProc > inputP; 
	  inputP.reset( new InputProc("input", fsHz, 10 /* bufferSize_s */, false /* doNormalize */) );
	  
	  shared_ptr <PreProc > ppP;
	  ppP.reset( new PreProc("preProc", inputP ) ); /* default parameters */

	  shared_ptr <GammatoneProc > gtP;
	  gtP.reset( new GammatoneProc("gammatoneProc", ppP ) ); /* default parameters */

	  shared_ptr <IHCProc > ihcP;
	  ihcP.reset( new IHCProc("innerHairCell", gtP, method ) );
	  												  
	  inputP->processChunk ( earSignals[0].data(), earSignals[0].size(), earSignals[1].data(), earSignals[1].size() );
	  inputP->releaseChunk(); 
	  
	  ppP->processChunk ();
	  ppP->releaseChunk();  	

	  gtP->processChunk ();
	  gtP->releaseChunk();

	  ihcP->processChunk ();
	  ihcP->releaseChunk();
	  	  	  
	  vector<shared_ptr<twoCTypeBlock<double> > > lOut = ihcP->getLeftWholeBufferAccessor();
	  vector<shared_ptr<twoCTypeBlock<double> > > rOut = ihcP->getRightWholeBufferAccessor();
  
	  matFiles::writeTFSMatFile(outputName.c_str(), lOut, rOut, fsHz);
  } 
  																			    
  return 0;  
}
