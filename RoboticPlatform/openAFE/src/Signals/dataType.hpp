#ifndef DATATYPE_HPP
#define DATATYPE_HPP

#include <stdint.h>
#include <vector>
#include <memory>	/* shared_ptr */


namespace openAFE {
			
	/* twoCTypeBlock : This is needed to save the
	 * first and the second parts of the last chunk from a 
	 * circular buffer
	 * */
	template<typename T>
	struct twoCTypeBlock {
		public :
			typedef std::shared_ptr<twoCTypeBlock<T> > twoCTypeBlockPtr;
			std::pair<T*, std::size_t> array1, array2;

			std::size_t getSize () {
				return array1.second + array2.second;
			}
			
			void setData( std::shared_ptr<twoCTypeBlock<T> > toCopy) {
				this->array1.first = toCopy->array1.first;
				this->array1.second = toCopy->array1.second;				
				this->array2.first = toCopy->array2.first;
				this->array2.second = toCopy->array2.second;
			}
			
			T *getPtr( std::size_t index ) {
				if ( array1.second > index )
					return array1.first + index;
				else return array2.first + index - array1.second;
			}			
			
	};
};

#endif /* DATATYPE_HPP */
