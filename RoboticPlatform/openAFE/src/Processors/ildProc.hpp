#ifndef ILDPROC_HPP
#define ILDPROC_HPP
	
#include "windowBasedProcs.hpp"

/* 
 * ILD Proc :
 * 
 * 
 * */
 
namespace openAFE {
	
	class ILDProc : public WindowBasedProcs {

		private:

			void processChannel ( const std::size_t ii, const std::size_t totalFrames,
								  const std::shared_ptr<twoCTypeBlock<double> > leftChannel,
								  const std::shared_ptr<twoCTypeBlock<double> > rightChannel );
								  
			inline
			void ild( double* frame_r, double* frame_l, double* value );
			
		public:
		
			ILDProc (const std::string nameArg, std::shared_ptr<IHCProc > upperProcPtr, double wSizeSec = 0.02, double hSizeSec = 0.01, windowType wname = _hann );

			~ILDProc ();
			
			void processChunk ();

	}; /* class ILDProc */
}; /* namespace openAFE */

#endif /* ILDPROC_HPP */
