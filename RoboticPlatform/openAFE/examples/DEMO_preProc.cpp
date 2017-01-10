#include <memory>
#include <iostream>

#include "../src/Processors/inputProc.hpp"
#include "../src/Processors/preProc.hpp"

#include "matFiles.hpp"

using namespace openAFE;
using namespace std;

int main(int argc, char **argv) {

  std::vector <std::vector<double> > earSignals;
  double fsHz;

  string dataPath;
  string outputName;  
  
  bool pp_bRemoveDC = false, pp_bPreEmphasis = false, pp_bNormalizeRMS = false, pp_bLevelScaling = false, pp_bMiddleEarFiltering = false, pp_bUnityComp = true;
  uint32_t pp_cutoffHzDC = 20;
  middleEarModel pp_middleEarModel = _jepsen;
  double pp_coefPreEmphasis = 0.97, pp_intTimeSecRMS = 0.5, pp_refSPLdB = 100;

  switch ( argc ) {
		  case 3:
			dataPath = argv[1];
			outputName = argv[2];
			break;
		  case 4:  
			dataPath = argv[1];
			outputName = argv[2];
			pp_bRemoveDC = *(argv[3]) != '0';
			break;
		  case 5:
			dataPath = argv[1];
			outputName = argv[2];
			pp_bRemoveDC = *(argv[3]) != '0';
			pp_cutoffHzDC = atoi(argv[4]);
			break;
		  case 6:
			dataPath = argv[1];
			outputName = argv[2];
			pp_bRemoveDC = *(argv[3]) != '0';
			pp_cutoffHzDC = atoi(argv[4]);
			pp_bPreEmphasis = *(argv[5]) != '0';
			break;
		  case 7:
			dataPath = argv[1];
			outputName = argv[2];
			pp_bRemoveDC = *(argv[3]) != '0';
			pp_cutoffHzDC = atoi(argv[4]);
			pp_bPreEmphasis = *(argv[5]) != '0';
			pp_coefPreEmphasis = atof(argv[6]);			
			break;	
		  case 8:
			dataPath = argv[1];
			outputName = argv[2];
			pp_bRemoveDC = *(argv[3]) != '0';
			pp_cutoffHzDC = atoi(argv[4]);
			pp_bPreEmphasis = *(argv[5]) != '0';
			pp_coefPreEmphasis = atof(argv[6]);	
			pp_bNormalizeRMS = *(argv[7]) != '0';
			break;
		  case 9:
			dataPath = argv[1];
			outputName = argv[2];
			pp_bRemoveDC = *(argv[3]) != '0';
			pp_cutoffHzDC = atoi(argv[4]);
			pp_bPreEmphasis = *(argv[5]) != '0';
			pp_coefPreEmphasis = atof(argv[6]);	
			pp_bNormalizeRMS = *(argv[7]) != '0';
			pp_intTimeSecRMS = atof(argv[8]);	
			break;	
		  case 10:
			dataPath = argv[1];
			outputName = argv[2];
			pp_bRemoveDC = *(argv[3]) != '0';
			pp_cutoffHzDC = atoi(argv[4]);
			pp_bPreEmphasis = *(argv[5]) != '0';
			pp_coefPreEmphasis = atof(argv[6]);	
			pp_bNormalizeRMS = *(argv[7]) != '0';
			pp_intTimeSecRMS = atof(argv[8]);	
			pp_bLevelScaling = *(argv[9]) != '0';
			break;	
		  case 11:
			dataPath = argv[1];
			outputName = argv[2];
			pp_bRemoveDC = *(argv[3]) != '0';
			pp_cutoffHzDC = atoi(argv[4]);
			pp_bPreEmphasis = *(argv[5]) != '0';
			pp_coefPreEmphasis = atof(argv[6]);	
			pp_bNormalizeRMS = *(argv[7]) != '0';
			pp_intTimeSecRMS = atof(argv[8]);	
			pp_bLevelScaling = *(argv[9]) != '0';
			pp_refSPLdB = atof(argv[10]);	
			break;	
		  case 12:
			dataPath = argv[1];
			outputName = argv[2];
			pp_bRemoveDC = *(argv[3]) != '0';
			pp_cutoffHzDC = atoi(argv[4]);
			pp_bPreEmphasis = *(argv[5]) != '0';
			pp_coefPreEmphasis = atof(argv[6]);	
			pp_bNormalizeRMS = *(argv[7]) != '0';
			pp_intTimeSecRMS = atof(argv[8]);	
			pp_bLevelScaling = *(argv[9]) != '0';
			pp_refSPLdB = atof(argv[10]);	
			pp_bMiddleEarFiltering = *(argv[11]) != '0';	
			break;	
		  case 13:
			dataPath = argv[1];
			outputName = argv[2];
			pp_bRemoveDC = *(argv[3]) != '0';
			pp_cutoffHzDC = atoi(argv[4]);
			pp_bPreEmphasis = *(argv[5]) != '0';
			pp_coefPreEmphasis = atof(argv[6]);	
			pp_bNormalizeRMS = *(argv[7]) != '0';
			pp_intTimeSecRMS = atof(argv[8]);	
			pp_bLevelScaling = *(argv[9]) != '0';
			pp_refSPLdB = atof(argv[10]);	
			pp_bMiddleEarFiltering = *(argv[11]) != '0';	
			if ( strcmp("lopezpoveda", argv[12]) == 0 ) pp_middleEarModel = _lopezpoveda;
			break;	
		  case 14:
			dataPath = argv[1];
			outputName = argv[2];
			pp_bRemoveDC = *(argv[3]) != '0';
			pp_cutoffHzDC = atoi(argv[4]);
			pp_bPreEmphasis = *(argv[5]) != '0';
			pp_coefPreEmphasis = atof(argv[6]);	
			pp_bNormalizeRMS = *(argv[7]) != '0';
			pp_intTimeSecRMS = atof(argv[8]);	
			pp_bLevelScaling = *(argv[9]) != '0';
			pp_refSPLdB = atof(argv[10]);	
			pp_bMiddleEarFiltering = *(argv[11]) != '0';	
			if ( strcmp("lopezpoveda", argv[12]) == 0 ) pp_middleEarModel = _lopezpoveda;
			pp_bUnityComp = *(argv[13]) != '0';
			break;																							
		  default:
			cerr << "The correct usage is : ./TEST_preProc inFilePath outputName pp_bRemoveDC pp_cutoffHzDC pp_bPreEmphasis pp_coefPreEmphasis pp_bNormalizeRMS  pp_intTimeSecRMS pp_bLevelScaling pp_refSPLdB pp_bMiddleEarFiltering  pp_middleEarModel pp_bUnityComp" << endl;
			return 0;
	  }
	    
  int result = matFiles::readMatFile(dataPath.c_str(), earSignals, &fsHz);

  if ( result == 0 ) { 
	  std::shared_ptr <InputProc > inputSignal; 
	  inputSignal.reset( new InputProc("input", fsHz, 10 /* bufferSize_s */, false /* doNormalize */) );

	  if ( pp_bMiddleEarFiltering )
		cout << "The middle ear filtering is not yet available." << endl;
		
	  std::shared_ptr <PreProc > ppSignal;
	  ppSignal.reset( new PreProc("preProc", inputSignal, pp_bRemoveDC,
														  pp_cutoffHzDC,
														  pp_bPreEmphasis,
														  pp_coefPreEmphasis,
														  pp_bNormalizeRMS,
														  pp_intTimeSecRMS,
														  pp_bLevelScaling,
														  pp_refSPLdB,
														  pp_bMiddleEarFiltering,
														  pp_middleEarModel,
														  pp_bUnityComp ) );																			  
																							  
	  inputSignal->processChunk ( earSignals[0].data(), earSignals[0].size(), earSignals[1].data(), earSignals[1].size() );
	  inputSignal->releaseChunk(); 
	  
	  ppSignal->processChunk ();
	  ppSignal->releaseChunk();  	
	  
	  std::shared_ptr<twoCTypeBlock<double> > lOut = ppSignal->getLeftWholeBufferAccessor();
	  std::shared_ptr<twoCTypeBlock<double> > rOut = ppSignal->getRightWholeBufferAccessor();
  
	  matFiles::writeTDSMatFile(outputName.c_str(), lOut, rOut, fsHz);
  }
  																			    
  return 0;  
}
