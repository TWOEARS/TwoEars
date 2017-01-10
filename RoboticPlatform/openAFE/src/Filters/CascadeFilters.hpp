#ifndef CASCADEFILTER_HPP
#define CASCADEFILTER_HPP

#include <stdint.h>
#include <vector>
#include <memory>
#include <assert.h>
#include <exception>
#include <string>

#include "GenericFilter.hpp"

#include <iostream>

namespace openAFE {

	template< typename T_in = double, typename T_out = double, typename T_b = double, typename T_a = double >
	class CascadeFilters {
		
	private:
	
		uint32_t cascadeOrder;
		typedef std::shared_ptr<GenericFilter<T_in,  T_out, T_b, T_a> > GenericFilterPtr;
		std::vector<GenericFilterPtr > filterVector;
		
	public:
	
		CascadeFilters(uint32_t cascadeOrder) {
			
			this->cascadeOrder = cascadeOrder;
			filterVector.reserve( cascadeOrder );
		}
		
		~CascadeFilters() {
			filterVector.clear();
		}

		inline
		void execFrame( T_in* src, T_out* dst ) {
			filterVector[0]->execFrame( src, dst );
			for ( std::size_t ii = 1 ; ii < cascadeOrder ; ++ii )
				filterVector[ii]->execFrame( dst, dst );
		}
		
		void exec( T_in* srcStart, const std::size_t lenSrc, T_out* destStart ) {
			if( cascadeOrder != filterVector.size() )
				throw std::string("Initialize all the filters before executing.");
			if ( srcStart == destStart ) {
				for ( std::size_t ii = 0 ; ii < cascadeOrder ; ++ii )
					filterVector[ii]->exec(srcStart, lenSrc, srcStart);
			} else {
				filterVector[0]->exec(srcStart, lenSrc, destStart);
				for ( std::size_t ii = 1 ; ii < cascadeOrder ; ++ii )
					filterVector[ii]->exec( destStart, lenSrc, destStart);		
			}
		}
		
		void setFilter ( const T_b* startB, const std::size_t lenB, const T_a* startA, const std::size_t lenA ) {
			if ( cascadeOrder > filterVector.size() ) {
				GenericFilterPtr thisFilter;
				thisFilter.reset( new GenericFilter<T_in,  T_out, T_b, T_a>( startB, lenB, startA, lenA ) );
				filterVector.push_back ( thisFilter );
			} else throw std::string("All the filters ars instantiated.");
		}
		
		uint32_t getCascadeOrder( ) {
			return this->cascadeOrder;
		}

	}; /* CascadeFilter */
}; /* namespace openAFE*/
#endif /* CASCADEFILTER_HPP */
