function out = applyFrequencyCutoffToFFT(originalFFT, freqCutoff, samplingInterval)
% Eliminates frequencies above cutoff from data represented in the frequency domain (FFT). 
% Input:
%   originalFFT       - matrix of row vectors, each an FFT
%   freqCutoff        - cutoff frequency (Hz)
%   samplingInterval  - (s)

assert(size(originalFFT,1) < size(originalFFT,2), 'Incompatible matrix or vector orientation')

timePoints = length(originalFFT);  % note: length of points in time domain same as length of FFT
freqStepSize = 1/(samplingInterval * timePoints);
freqCutoffPts = round(freqCutoff / freqStepSize);

% eliminate frequencies beyond cutoff (middle of matrix given fft representation)
out = originalFFT;
out(:, 1+freqCutoffPts:end-freqCutoffPts) = 0;

end
