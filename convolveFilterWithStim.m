function generatorSignal = convolveFilterWithStim(filter, stim)

filterLength = size(filter,2);
numPts = size(stim,2); 
numEpochs = size(stim,1);

if filterLength ~= numPts
    diff = abs(filterLength - numPts);
    
    %finds out if the length of the difference is even or odd
    if mod(diff,2) ~= 0
        interval(1) = round(diff/2);
        interval(2) = round(diff/2) - 1;
    else
        interval(1) = diff/2;
        interval(2) = interval(1);
    end
    
    midpoint = round(filterLength / 2);
    
    %remove zeros from filter if stimuli length is shorter; otherwise, pad
    %with zeros - in either case, start modification from the middle of
    %filter
    if filterLength > numPts
    	filter(midpoint-interval(1)+1:midpoint+interval(2)) = [];
    else
    	filter = [filter(1:midpoint) zeros(1,diff-1) filter(midpoint:end)];
    end
end

filterFFT = fft(filter);

generatorSignalFFT = zeros(numEpochs, numPts);
generatorSignal = zeros(numEpochs, numPts);

for ii = 1:numEpochs
    stimSingle = stim(ii,:);
    stimSingleFFT = fft(stimSingle);
    generatorSignalFFT(ii,:) = filterFFT .* stimSingleFFT;
    generatorSignal(ii,:) = real(ifft(generatorSignalFFT(ii,:))); 
end
end