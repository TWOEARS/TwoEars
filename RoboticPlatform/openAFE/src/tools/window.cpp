#include "window.hpp"

	std::vector<double> openAFE::hamming( std::size_t n ) {
	  std::vector<double> t(n);

	  if (n == 1)
		t[0] = 0.08;
	  else
		for ( std::size_t i = 0 ; i < n ; i++ )
		  t[i] = (0.54 - 0.46 * std::cos(2.0 * M_PI * i / (n - 1)));

	  return t;
	}

	std::vector<double> openAFE::hanning( std::size_t n ) {
	  std::vector<double> t(n);

	  for ( std::size_t i = 0 ; i < n ; i++ )
		t[i] = 0.5 * (1.0 - std::cos(2.0 * M_PI * (i + 1) / (n + 1)));

	  return t;
	}

	std::vector<double> openAFE::hann(std::size_t n) {
		std::vector<double>  t(n);

		for ( std::size_t i = 0 ; i < n ; i++ )
			t[i] = 0.5 * (1.0 - std::cos(2.0 * M_PI * i / (n - 1)));

	  return t;
	}

	std::vector<double> openAFE::blackman(std::size_t n) {
	  std::vector<double>  t(n);

	  for ( std::size_t i = 0 ; i < n ; i++ )
		t[i] = 0.42 - 0.5 * std::cos(2.0 * M_PI * i / (n - 1)) + 0.08 * std::cos(4.0 * M_PI * i / (n - 1));

	  return t;
	}

	std::vector<double> openAFE::triang(std::size_t n) {
	  std::vector<double> t(n);

	  if (n % 2) { // Odd
		for (std::size_t i = 0; i < n / 2; i++)
		  t[i] = t[n - i - 1] = 2.0 * (i + 1) / (n + 1);
		t[n / 2] = 1.0;
	  }
	  else
		for (std::size_t i = 0; i < n / 2; i++)
		  t[i] = t[n - i - 1] = (2.0 * i + 1) / n;

	  return t;
	}

	std::vector<double> openAFE::sqrt_win(std::size_t n) {
	  std::vector<double> t(n);

	  if (n % 2) { // Odd
		for (std::size_t i = 0; i < n / 2; i++)
		  t[i] = t[n - i - 1] = std::sqrt(2.0 * (i + 1) / (n + 1));
		t[n / 2] = 1.0;
	  }
	  else
		for (std::size_t i = 0; i < n / 2; i++)
		  t[i] = t[n - i - 1] = std::sqrt((2.0 * i + 1) / n);

	  return t;
	}
