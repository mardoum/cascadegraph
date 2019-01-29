function convolution = convolveFilterWithStim(filter, stim, filterHasAnticausalHalf)
% Convolves an input vector with each row of an input matrix and returns matrix of convolutions. The
% length of the output matrix is the max of the lengths of the two inputs.
% Input:
%   filter  - vector representing filter with no zero padding
%   stim    - matrix of row vectors to be convolved with filter
%   filterHasAnticausalHalf  - boolean

assert(size(stim,1) < size(stim,2), 'Incompatible matrix or vector orientation')

assert(rem(length(filter), 2) == 0, 'Filter must have an even number of points')

filterLength = length(filter);
stimLength = size(stim,2); 
numEpochs = size(stim,1);

stim = stim - repmat(mean(stim,2), 1, length(stim));

% Zero pad the filter or stimulus vectors so that they are the same length and can be convolved by
% pointwise multiplication in the frequency domain.
lengthDiff = abs(filterLength - stimLength);
if filterLength < stimLength
    midpoint = length(filter) / 2;
    if filterHasAnticausalHalf
        filter = [filter(1:midpoint) zeros(1,lengthDiff) filter(midpoint+1:end)];
    else
        filter = [filter zeros(1,lengthDiff)];
    end
else
    stim = [stim zeros(numEpochs, lengthDiff)];
end

filterFFT = fft(filter);
stimFFT   = fft(stim, [], 2);
convolutionFFT = stimFFT .* repmat(filterFFT, numEpochs, 1);
convolution = real(ifft(convolutionFFT, [], 2));

end
