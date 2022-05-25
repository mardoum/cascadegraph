function out = applyFrequencyCutoffToFFT(originalFFT, freqCutoff, samplingInterval)
% Eliminates frequencies above cutoff from data represented in the frequency domain (FFT). 
% Input:
%   originalFFT       - matrix of row vectors, each an FFT
%   freqCutoff        - cutoff frequency (Hz)
%   samplingInterval  - (s)

timePoints = size(originalFFT, 2);  % note: length of points in time domain same as length of FFT
freqStepSize = 1/(samplingInterval * timePoints);
freqCutoffPts = round(freqCutoff / freqStepSize);

% Eliminate frequencies beyond cutoff (middle of matrix given fft representation)
out = originalFFT;
out(:, 1+freqCutoffPts:end-freqCutoffPts) = 0;

end
