#ifndef WINDOWBASEDLAGPROCS_HPP
#define WINDOWBASEDLAGPROCS_HPP

#include <assert.h>

#include "windowBasedProcs.hpp"	
#include "LAGProcessor.hpp"
#include "ihcProc.hpp"

#include "../tools/window.hpp"

/* 
 * 
 * 
 * 
 * */
 
namespace openAFE {
	
	class WindowBasedLAGProcs : public LAGProcessor<double > {

		protected:
		
			windowType wname;		       		// Window shape descriptor (see window.m)
			double wSizeSec;    			  	// Window duration in seconds
			double hSizeSec;    			  	// Step size between windows in seconds

			uint64_t wSize;															// Window duration in samples
			uint64_t hSize;															// Step size between windows in samples
			std::vector<double> win;         										// Window vector
			std::shared_ptr <TimeFrequencySignal<double> > buffer_l, buffer_r;    	// Buffered input signals

			uint32_t nLags;
			
			std::shared_ptr<IHCProc > upperProcPtr;

			/* Will be used to append to PMZ */
			std::vector<double> zerosVector;
			std::shared_ptr<twoCTypeBlock<double> > zerosAccecor;
						
			// Output sampling frequency;
			uint32_t calcFsOut( double hSizeSec );

			virtual void prepareForProcessing();
			
		public:
		
			WindowBasedLAGProcs (const std::string nameArg, std::shared_ptr<IHCProc > upperProcPtr, procType typeOfThisProc, std::size_t nLag, double wSizeSec = 0.02, double hSizeSec = 0.01, windowType wname = _hann );

			~WindowBasedLAGProcs ();
			
			void processChunk () = 0;

			bool operator==( WindowBasedLAGProcs& toCompare );
			
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
			
	}; /* class WindowBasedLAGProcs */
}; /* namespace openAFE */

#endif /* WINDOWBASEDLAGPROCS_HPP */
