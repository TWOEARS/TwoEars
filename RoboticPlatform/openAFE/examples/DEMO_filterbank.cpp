#include <memory>
#include <iostream>

#include "../src/Processors/inputProc.hpp"
#include "../src/Processors/preProc.hpp"
#include "../src/Processors/gammatoneProc.hpp"

#include "matFiles.hpp"

using namespace openAFE;
using namespace std;

int main(int argc, char **argv) {

  vector <vector<double> > earSignals;
  double fsHz;
  
  string dataPath;
  string outputName;  

  filterBankType fb_type = _gammatoneFilterBank;
  double fb_lowFreqHz = 80;
  double fb_highFreqHz = 8000;
  double fb_nERBs = 1;
  uint32_t fb_nChannels = 0;	
  double* fb_cfHz = nullptr;		
  size_t fb_cfHz_length = 0;		
  uint32_t fb_nGamma = 4;
  double fb_bwERBs = 1.0180;

  switch ( argc ) {
		  case 3:
			dataPath = argv[1];
			outputName = argv[2];
			break;
		  case 4:  
			dataPath = argv[1];
			outputName = argv[2];
			fb_lowFreqHz = atof(argv[3]);
			break;
		  case 5:
			dataPath = argv[1];
			outputName = argv[2];
			fb_lowFreqHz = atof(argv[3]);
			fb_highFreqHz = atof(argv[4]);
			break;
		  case 6:
			dataPath = argv[1];
			outputName = argv[2];
			fb_lowFreqHz = atof(argv[3]);
			fb_highFreqHz = atof(argv[4]);
			fb_nERBs = atof(argv[5]);
			break;
		  case 7:
			dataPath = argv[1];
			outputName = argv[2];
			fb_lowFreqHz = atof(argv[3]);
			fb_highFreqHz = atof(argv[4]);
			fb_nERBs = atof(argv[5]);
			fb_nChannels = atoi(argv[6]);			
			break;	
		  case 8:
			dataPath = argv[1];
			outputName = argv[2];
			fb_lowFreqHz = atof(argv[3]);
			fb_highFreqHz = atof(argv[4]);
			fb_nERBs = atof(argv[5]);
			fb_nChannels = atoi(argv[6]);
			fb_nGamma = atoi(argv[7]);
			break;
		  case 9:
			dataPath = argv[1];
			outputName = argv[2];
			fb_lowFreqHz = atof(argv[3]);
			fb_highFreqHz = atof(argv[4]);
			fb_nERBs = atof(argv[5]);
			fb_nChannels = atoi(argv[6]);
			fb_nGamma = atoi(argv[7]);
			fb_bwERBs = atof(argv[8]);	
			break;																		
		  default:
			cerr << "The correct usage is : ./TEST_filterbank inFilePath outputName fb_lowFreqHz fb_highFreqHz fb_nERBs fb_nChannels fb_nGamma fb_bwERBs" << endl;
			return 0;
	  }
																				    	  
  int result = matFiles::readMatFile(dataPath.c_str(), earSignals, &fsHz);

  if ( result == 0 ) {
	  shared_ptr <InputProc > inputP; 
	  inputP.reset( new InputProc("input", fsHz, 10 /* bufferSize_s */, false /* doNormalize */) );

	  shared_ptr <PreProc > ppP;
	  ppP.reset( new PreProc("preProc", inputP ) ); /* default parameters */

	  shared_ptr <GammatoneProc > gtP;
	  gtP.reset( new GammatoneProc("gammatoneProc", ppP ,fb_type,
														 fb_lowFreqHz,
														 fb_highFreqHz,
														 fb_nERBs,
														 fb_nChannels,
														 fb_cfHz,
														 fb_cfHz_length,
														 fb_nGamma,
														 fb_bwERBs ) );
				  
	  inputP->processChunk ( earSignals[0].data(), earSignals[0].size(), earSignals[1].data(), earSignals[1].size() );
	  inputP->releaseChunk(); 
	  
	  ppP->processChunk ();
	  ppP->releaseChunk();  	

	  gtP->processChunk ();
	  gtP->releaseChunk();
	  	  
	  vector<shared_ptr<twoCTypeBlock<double> > > lOut = gtP->getLeftWholeBufferAccessor();
	  vector<shared_ptr<twoCTypeBlock<double> > > rOut = gtP->getRightWholeBufferAccessor();
  
	  matFiles::writeTFSMatFile(outputName.c_str(), lOut, rOut, fsHz);
  }
  																			    
  return 0;  
}
