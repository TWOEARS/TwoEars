#include <memory>
#include <iostream>

#include "../src/Processors/inputProc.hpp"
#include "../src/Processors/preProc.hpp"
#include "../src/Processors/gammatoneProc.hpp"
#include "../src/Processors/ihcProc.hpp"
#include "../src/Processors/ratemap.hpp"

#include "matFiles.hpp"

using namespace openAFE;
using namespace std;

int main(int argc, char **argv) {

  vector <vector<double> > earSignals;
  double fsHz;
  
  string dataPath;  
  string outputName; 

  double wSizeSec = 0.02;
  double hSizeSec = 0.01;
  scalingType scailingArg = _power;
  double decaySec = 0.008;
  windowType wname = _hann;
  
  switch ( argc ) {
	case 3:
		dataPath = argv[1];
		outputName = argv[2];
	break;
	case 4:  
		dataPath = argv[1];
		outputName = argv[2];
		wSizeSec = atof(argv[3]);
		break;
	case 5:  
		dataPath = argv[1];
		outputName = argv[2];
		wSizeSec = atof(argv[3]);
		hSizeSec = atof(argv[4]);
		break;		
	case 6:  
		dataPath = argv[1];
		outputName = argv[2];
		wSizeSec = atof(argv[3]);
		hSizeSec = atof(argv[4]);
		if ( strcmp("power", argv[5]) == 0 ) wname = _hamming;
		else if ( strcmp("magnitude", argv[5]) == 0 ) wname = _hanning;
		else { cerr << "Available scaling types are : power, magnitude" << endl;
			   return 0;
			 }
		break;
	case 7:  
		dataPath = argv[1];
		outputName = argv[2];
		wSizeSec = atof(argv[3]);
		hSizeSec = atof(argv[4]);
		if ( strcmp("power", argv[5]) == 0 ) wname = _hamming;
		else if ( strcmp("magnitude", argv[5]) == 0 ) wname = _hanning;
		else { cerr << "Available scaling types are : power, magnitude" << endl;
			   return 0;
			 }
		decaySec = atof(argv[6]);
		break;
	case 8:  
		dataPath = argv[1];
		outputName = argv[2];
		wSizeSec = atof(argv[3]);
		hSizeSec = atof(argv[4]);
		if ( strcmp("power", argv[5]) == 0 ) wname = _hamming;
		else if ( strcmp("magnitude", argv[5]) == 0 ) wname = _hanning;
		else { cerr << "Available scaling types are : power, magnitude" << endl;
			   return 0;
			 }
		decaySec = atof(argv[6]);		
		if ( strcmp("hamming", argv[7]) == 0 ) wname = _hamming;
		else if ( strcmp("hanning", argv[7]) == 0 ) wname = _hanning;
		else if ( strcmp("hann", argv[7]) == 0 ) wname = _hann;
		else if ( strcmp("blackman", argv[7]) == 0 ) wname = _blackman;
		else if ( strcmp("triang", argv[7]) == 0 ) wname = _triang;
		else if ( strcmp("sqrt", argv[7]) == 0 ) wname = _sqrt_win;
		else { cerr << "Available windows are : hamming, hanning, hann, blackman, triang, sqrt" << endl;
			   return 0;
			 }		
		break;		
	default:
		cerr << "The correct usage is : ./TEST_ratemap inFilePath outputName wSizeSec hSizeSec scailingArg decaySec wname" << endl;
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
	  ihcP.reset( new IHCProc("innerHairCell", gtP ) ); /* default parameters */

	  shared_ptr <Ratemap > rmP;
	  rmP.reset( new Ratemap("rm", ihcP, wSizeSec, hSizeSec, scailingArg, decaySec, wname ) );	 
	  	  												  
	  inputP->processChunk ( earSignals[0].data(), earSignals[0].size(), earSignals[1].data(), earSignals[1].size() );
	  inputP->releaseChunk(); 
		  
	  ppP->processChunk ();
	  ppP->releaseChunk();

	  gtP->processChunk ();
	  gtP->releaseChunk();

	  ihcP->processChunk ();
	  ihcP->releaseChunk();
	  
	  rmP->processChunk ();
	  rmP->releaseChunk();
	  	  	  	  	  
	  vector<shared_ptr<twoCTypeBlock<double> > > lOut = rmP->getLeftWholeBufferAccessor();
	  vector<shared_ptr<twoCTypeBlock<double> > > rOut = rmP->getRightWholeBufferAccessor();
  
	  matFiles::writeTFSMatFile(outputName.c_str(), lOut, rOut, fsHz);
  }
  																			    
  return 0;  
}
