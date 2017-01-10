#ifndef GAMMATONEPROC_HPP
#define GAMMATONEPROC_HPP
	
#include "TFSProcessor.hpp"
#include "preProc.hpp"	

#include "../Filters/GammatoneFilter.hpp"

#include "../tools/mathTools.hpp"


/* 
 * GamamtoneProc :
 * 
 * 
 * */
 
namespace openAFE {
	
	enum filterBankType {
		_gammatoneFilterBank,
		_drnlFilterBank
	};
	
	class GammatoneProc : public TFSProcessor<double > {

		private:

			filterBankType fb_type;

			std::vector<double> cfHz;            									// Filters center frequencies
			double fb_nERBs;          												// Distance between neighboring filters in ERBs
			uint32_t fb_nGamma;       							    				// Gammatone order of the filters
			double fb_bwERBs;        							    				// Bandwidth of the filters in ERBs
			double fb_lowFreqHz;       							   	 				// Lowest center frequency used at instantiation
			double fb_highFreqHz;      							    				// Highest center frequency used at instantiation
			
            typedef std::shared_ptr < GammatoneFilter > gammatoneFilterPtr;
            typedef std::vector <gammatoneFilterPtr > filterPtrVector;
			filterPtrVector leftFilters, rightFilters;		    				// Array of filter pointer objects
			      
			std::shared_ptr<PreProc > upperProcPtr;
			      			
            std::size_t verifyParameters( filterBankType fb_type, double fb_lowFreqHz, double fb_highFreqHz, double fb_nERBs,
									 uint32_t fb_nChannels, double* fb_cfHz, std::size_t fb_cfHz_length, uint32_t fb_nGamma, double fb_bwERBs );
			
			void populateFilters( filterPtrVector& filters );


			void processChannel ( const std::size_t ii, const std::shared_ptr<twoCTypeBlock<double> > leftChannel, const std::shared_ptr<twoCTypeBlock<double> > rightChannel );
														
		public:
		
			GammatoneProc (const std::string nameArg, std::shared_ptr<PreProc > upperProcPtr, filterBankType fb_type = _gammatoneFilterBank,
																							  double fb_lowFreqHz = 80,
																							  double fb_highFreqHz = 8000,
																							  double fb_nERBs = 1,
																							  uint32_t fb_nChannels = 0,		
																							  double* fb_cfHz = nullptr,		
																							  std::size_t fb_cfHz_length = 0,		
																							  uint32_t fb_nGamma = 4,
																							  double fb_bwERBs = 1.0180 );
				
			~GammatoneProc ();
			
			void processChunk ( );
			
			void prepareForProcessing ();
			
			/* Comapres informations and the current parameters of two processors */
			bool operator==( GammatoneProc& toCompare );

			// getters
			const filterBankType get_fb_type();
			const double get_fb_lowFreqHz();
			const double get_fb_highFreqHz();
			const double get_fb_nERBs();
			const uint32_t get_fb_nGamma();
			const double get_fb_bwERBs();
			const double* get_fb_cfHz();

			// setters
			void set_fb_nGamma(const uint32_t arg);
			void set_fb_bwERBs(const double arg);

			std::string get_upperProcName();

	}; /* class GammatoneProc */
}; /* namespace openAFE */

#endif /* GAMMATONEPROC_HPP */
