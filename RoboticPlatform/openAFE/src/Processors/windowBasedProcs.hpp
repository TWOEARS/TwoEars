#ifndef WINDOWBASEDPROCS_HPP
#define WINDOWBASEDPROCS_HPP

#include <assert.h>
	
#include "TFSProcessor.hpp"
#include "ihcProc.hpp"

#include "../tools/window.hpp"

/* 
 * ILD Proc :
 * 
 * 
 * */
 
namespace openAFE {

	enum windowType {
        _hamming,
        _hanning,
        _hann,
        _blackman,
        _triang,
        _sqrt_win
	};
	
	class WindowBasedProcs : public TFSProcessor<double > {

		protected:
		
			windowType wname;		       		// Window shape descriptor (see window.m)
			double wSizeSec;    			  	// Window duration in seconds
			double hSizeSec;    			  	// Step size between windows in seconds

			uint64_t wSize;															// Window duration in samples
			uint64_t hSize;															// Step size between windows in samples
			std::vector<double> win;         										// Window vector
			std::shared_ptr <TimeFrequencySignal<double> > buffer_l, buffer_r;    	// Buffered input signals

			uint32_t fb_nChannels;
			
			std::shared_ptr<IHCProc > upperProcPtr;

			/* Will be used to append to PMZ */
			std::vector<double> zerosVector;
			std::shared_ptr<twoCTypeBlock<double> > zerosAccecor;
						
			// Output sampling frequency;
			uint32_t calcFsOut( double ild_hSizeSec );

			virtual void prepareForProcessing();
			
		public:
		
			WindowBasedProcs (const std::string nameArg, std::shared_ptr<IHCProc > upperProcPtr, procType typeOfThisProc, double wSizeSec = 0.02, double hSizeSec = 0.01, windowType wname = _hann, scalingType scailingArg = _magnitude );

			~WindowBasedProcs ();
			
			void processChunk () = 0;

			bool operator==( WindowBasedProcs& toCompare );
			
			// getters
			const double get_wSizeSec();
			const double get_hSizeSec();
			const windowType get_wname();
			
			const uint32_t get_nChannels();

			// setters			
			void set_wSizeSec(const double arg);
			void set_hSizeSec(const double arg);
			void set_wname(const windowType arg);

			std::string get_upperProcName();
			
	}; /* class WindowBasedProcs */
}; /* namespace openAFE */

#endif /* WINDOWBASEDPROCS_HPP */
