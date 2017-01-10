#ifndef RATEMAP_HPP
#define RATEMAP_HPP
	
#include "windowBasedProcs.hpp"

#include "../Filters/leakyIntegratorFilter.hpp"

/* 
 * RATEMAP Proc :
 * The ratemap represents a map of auditory nerve firing rates [1], computed
 * from the inner hair-cell signal representation for individual frequency 
 * channels. 
 * 
 * 
 *  Reference:
 *  [1] Brown, G. J. and Cooke, M. P. (1994), "Computational auditory scene
 *      analysis," ComputerSpeech and Language 8(4), pp. 297?336.
 * 
 * */
 
namespace openAFE {

	class Ratemap : public WindowBasedProcs {

		private:

			typedef std::shared_ptr< leakyIntegratorFilter > leakyIntegratorFilterPtr;
            typedef std::vector <leakyIntegratorFilterPtr > filterPtrVector;
            
            double decaySec;
			scalingType scailing;
			
			filterPtrVector rmFilter_l, rmFilter_r;

			void populateFilters( filterPtrVector& filterVec, std::size_t numberOfChannels, double fs );

			void prepareForProcessing();

			void processFilter (  const std::size_t ii,
								  const std::shared_ptr<twoCTypeBlock<double> > leftChannel,
								  const std::shared_ptr<twoCTypeBlock<double> > rightChannel );			
								  

			void processWindow (  const std::size_t ii, const std::size_t totalFrames,
										   const std::shared_ptr<twoCTypeBlock<double> > leftChannel,
										   const std::shared_ptr<twoCTypeBlock<double> > rightChannel ); 
										   								  
		public:
		
			Ratemap (const std::string nameArg, std::shared_ptr<IHCProc > upperProcPtr, double wSizeSec = 0.02, double hSizeSec = 0.01, scalingType scailingArg = _power, double decaySec = 0.008, windowType wname = _hann );

			~Ratemap ();
			
			void processChunk ();
			
			// getters
			const double get_rm_decaySec();
			const scalingType get_rm_scailing();
  
			// setters			
			void set_rm_decaySec(const double arg);
			void set_rm_scailing(const scalingType arg);

			
	}; /* class Ratemap */
}; /* namespace openAFE */

#endif /* RATEMAP_HPP */
