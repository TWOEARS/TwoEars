#ifndef IHCPROC_HPP
#define IHCPROC_HPP

#include <memory>
	
#include "TFSProcessor.hpp"
#include "gammatoneProc.hpp"

#include "../Filters/bwFilter.hpp"

#include "../tools/mathTools.hpp"

/* 
 * Inner Hair Cell Proc :
 * 
 * 
 * */
 
namespace openAFE {

	enum ihcMethod {
        _none,
        _halfwave,
        _fullwave,
        _square,
        _hilbert,
        _joergensen,
        _dau,
        _breebart,
        _bernstein
	};

	class IHCProc : public TFSProcessor<double > {

		private:

			typedef std::shared_ptr< bwFilter > bwFilterPtr;
            typedef std::vector <bwFilterPtr > filterPtrVector;
			
			ihcMethod method;
			filterPtrVector ihcFilter_l, ihcFilter_r;			
			std::shared_ptr<GammatoneProc > upperProcPtr;

			uint32_t fb_nChannels;
				
			void populateFilters( filterPtrVector& filters );

			inline
			void processNone  ( const std::size_t ii, const std::shared_ptr<twoCTypeBlock<double> > leftChannel, const std::shared_ptr<twoCTypeBlock<double> > rightChannel );
			
			inline
			void processHalfWave  ( const std::size_t ii, const std::shared_ptr<twoCTypeBlock<double> > leftChannel, const std::shared_ptr<twoCTypeBlock<double> > rightChannel );

			inline
			void processFullWave  ( const std::size_t ii, const std::shared_ptr<twoCTypeBlock<double> > leftChannel, const std::shared_ptr<twoCTypeBlock<double> > rightChannel );

			inline
			void processSquare  ( const std::size_t ii, const std::shared_ptr<twoCTypeBlock<double> > leftChannel, const std::shared_ptr<twoCTypeBlock<double> > rightChannel );
						
			inline
			void processDAU ( const std::size_t ii, const std::shared_ptr<twoCTypeBlock<double> > leftChannel, 
																					 const std::shared_ptr<twoCTypeBlock<double> > rightChannel, 
																					 bwFilterPtr filter_l,
																					 bwFilterPtr filter_r );
																					 
			void processChannel ( const std::size_t ii,
									  const std::shared_ptr<twoCTypeBlock<double> > leftChannel,
									  const std::shared_ptr<twoCTypeBlock<double> > rightChannel );

		public:
																		
			IHCProc (const std::string nameArg, std::shared_ptr<GammatoneProc > upperProcPtr, ihcMethod method = _dau  );
			
			~IHCProc ();
			
			void prepareForProcessing();
			
			void processChunk ( );
			
			/* Comapres informations and the current parameters of two processors */
			bool operator==( IHCProc& toCompare );

			// getters
			const ihcMethod get_ihc_method();

			// setters			
			void set_ihc_method(const ihcMethod arg);

			std::string get_upperProcName();

	}; /* class IHCProc */
}; /* namespace openAFE */

#endif /* IHCPROC_HPP */
