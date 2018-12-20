function generatorSignal = convolveFilterWithStim(filter, stim)

filterHalves = length(fieldnames(filter));

if filterHalves == 2
    filter = [filter.positiveTime filter.negativeTime];
else
    filter = [filter.positiveTime];
end

filterLength = size(filter,2);
numPts = size(stim,2); 
numEpochs = size(stim,1);

%Zero pad the filter or stimulus vectors so that they are the same length
%and can be convolved by pointwise multiplication in the frequency domain.
if filterLength ~= numPts
    diff = abs(filterLength - numPts);
    
    if filterLength < numPts
        zeroPad = zeros(1,diff);
        midpoint = round(length(filter) / 2);
        filter = [filter(1:midpoint) zeroPad filter(midpoint+1:end)];
        genSigLength = numPts;
    else
        zeroPad = zeros(numEpochs, diff);
    	stim = [stim zeroPad];  
        genSigLength = filterLength;
    end
else
    genSigLength = numPts;
end

filterFFT = fft(filter);

generatorSignalFFT = zeros(numEpochs, genSigLength);
generatorSignal = zeros(numEpochs, genSigLength);

for ii = 1:numEpochs
    stimSingle = stim(ii,:);
    stimSingleFFT = fft(stimSingle);
    generatorSignalFFT(ii,:) = filterFFT .* stimSingleFFT;
    generatorSignal(ii,:) = real(ifft(generatorSignalFFT(ii,:))); 
end
end

