function [filterCausal, filterAnticausal] = getFilter(stim, response, filterPts, ...
    correctStimPower, frequencyCutoff, samplingInterval)
% Computes filter that predicts response given stimulus. This is the cross-correlation between
% stimulus and response.
% Input:
%   stim       - matrix of row vectors
%   response   - matrix of row vectors
%   filterPts  - length of filter (one side of filter, causal or anti-causal half)
%   correctStimPower  - (optional) boolean, controls whether filter power is divided by stimulus
%                       power
%   frequencyCutoff   - (optional) used, along with samplingInterval, to apply frequency cutoff to
%                       filter. Must also supply a sampling frequency.
%   samplingInterval  - (optional) used to apply frequency cutoff to filter.
% Output:
%   filterCausal      - causal half of filter (acts on stimuli occurring before time 0)
%   filterAnticausal  - anticausal half of filter (acts on stimuli occurring after time 0).
%                       Structure in this half is entirely due to auto-correlation in stimulus.

assert(size(stim,1) < size(stim,2) && size(response,1) < size(response,2), ...
    'Incompatible matrix or vector orientation')

assert(ismember(nargin, [3, 4, 6]), ...
    '3, 4, or 6 inputs must be supplied. frequencyCutoff and samplingInterval are optional but must go together')

stimFFT = fft(stim, [], 2);
respFFT = fft(response, [], 2);
filterFFT = mean(respFFT .* conj(stimFFT), 1);

% normalize by stimulus power
if nargin > 3 && correctStimPower
    filterFFT = filterFFT ./ mean(stimFFT .* conj(stimFFT), 1);
end

% numPts = size(stim,2);
% filterFFT = filterFFT / numPts;  % what's the purpose of this?

% frequency cutoff
if nargin > 4
    filterFFT = applyFrequencyCutoffToFFT(filterFFT, frequencyCutoff, samplingInterval);
end

filterFFT(1) = 0;  % remove DC component

filterFull = real(ifft(filterFFT));  % transform back to time domain

% save causal and anticausal filter portions, each cut down to length = filterPoints
filterCausal     = filterFull(1 : filterPts);
filterAnticausal = filterFull(end - filterPts + 1 : end);

end
