function snr = addSnrs( snrs )

snr = 0;
for ii = 1 : numel( snrs )
    snr = snr + 10^(-snrs(ii)/10);
end
snr = 1 / snr;
snr = 10 * log10( snr );
