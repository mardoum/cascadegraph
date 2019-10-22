function [filterCausal, filterAnticausal] = computeFilter(stim, response, filterPts, ...
    correctStimPower, frequencyCutoff, samplingInterval)
% Computes filter that best predicts response given white noise stimulus. This
% is the cross-correlation between stimulus and response.
%
% Input:
%   stim       - matrix of row vectors
%   response   - matrix of row vectors
%   filterPts  - length of filter (one side of filter, causal or anti-causal
%                half)
%   correctStimPower  - (optional) boolean, controls whether filter power is
%                       divided by stimulus power
%   frequencyCutoff   - (optional) used, along with samplingInterval, to apply
%                       frequency cutoff to filter. Must also supply a sampling 
%                       frequency.
%   samplingInterval  - (optional) used to apply frequency cutoff to filter.
%
% Output:
%   filterCausal      - causal half of filter (acts on stimuli occurring before
%                       time 0)
%   filterAnticausal  - anticausal half of filter (acts on stimuli occurring
%                       after time 0). Structure in this half is entirely due to
%                       auto-correlation in stimulus.

assert(ismember(nargin, [3, 4, 6]), ['3, 4, or 6 inputs must be supplied. ' ...
    'frequencyCutoff and samplingInterval are optional but must go together'])

stimFFT = fft(stim, [], 2);
respFFT = fft(response, [], 2);

filterFFT = mean(respFFT .* conj(stimFFT), 1);

% Normalize by stimulus power
if nargin > 3 && correctStimPower
    filterFFT = filterFFT ./ mean(stimFFT .* conj(stimFFT), 1);
end

% Apply frequency cutoff
if nargin > 4
    filterFFT = applyFrequencyCutoffToFFT(filterFFT, frequencyCutoff, samplingInterval);
end

filterFFT(1) = 0;                       % remove DC component
filterFull = real(ifft(filterFFT));     % transform back to time domain

% Save causal and anticausal filter portions, each cut down to length = filterPoints
filterCausal     = filterFull(1 : filterPts);
filterAnticausal = filterFull(end - filterPts + 1 : end);

end