function [filterCausal, filterAnticausal] = getFilter(stim, response, params)
% Computes filter that predicts response given stimulus. This is the cross-correlation between
% stimulus and response.
% Input:
%   stim      - matrix of row vectors
%   response  - matrix of row vectors
%   params    - struct of parameters (temp)
% Output:
%   filterCausal      - causal half of filter (representing stimuli occurring before time 0)
%   filterAnticausal  - anticausal half of filter (representing stimuli occurring after time 0).
%                       Structure in this half is entirely due to auto-correlation in stimulus.

assert(size(stim,1) < size(stim,2) && size(response,1) < size(response,2), ...
    'Incompatible matrix or vector orientation')

% VECTORIZED version
stimFFT = fft(stim, [], 2);
respFFT = fft(response, [], 2);
filterFFT = mean(respFFT .* conj(stimFFT));

% filterFFT = filterFFT ./ mean(stimFFT .* conj(stimFFT));  % TODO: make this optional, since in some cases could cause blow-up


% % LOOP version
% % loop across all epochs to compute filter
% numEpochs = size(stim,1);
% filterFFT = zeros(1,numPts);
% for ii = 1:size(response, 1)
%     responseSingle = response(ii, :);
%     stimSingle = stim(ii, :);
%     
%     dataFFT = fft(responseSingle);
%     stmFFT = fft(stimSingle);
%     filterFFT = filterFFT + conj(stmFFT) .* dataFFT; 
% end
% filterFFT = filterFFT / numEpochs;  % to get average over epochs


% numPts = size(stim,2);
% filterFFT = filterFFT / numPts;  % what's the purpose of this?

% frequency cutoff, remove DC component, ifft
filterFFT = applyFrequencyCutoffToFFT(filterFFT, params.frequencyCutoff, params.samplingInterval);
filterFFT(1) = 0;  % remove DC component
filterFull = real(ifft(filterFFT));

% save causal and anticausal filter portions, each cut down to length = filterPoints
filterCausal     = filterFull(1 : params.filterPts);
filterAnticausal = filterFull(end - params.filterPts + 1 : end);

end
