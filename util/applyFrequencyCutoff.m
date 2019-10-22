function out = applyFrequencyCutoff(original, freqCutoff, samplingInterval)
% Eliminates frequencies above cutoff from data represented in the time domain. 
% Input:
%   original          - matrix of row vectors in time domain
%   freqCutoff        - cutoff frequency (Hz)
%   samplingInterval  - (s)

fftOriginal = fft(original, [], 2);
fftCutoff = applyFrequencyCutoffToFFT(fftOriginal, freqCutoff, samplingInterval);
out = real(ifft(fftCutoff, [], 2));

end
