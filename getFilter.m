%This function computes the cross-correlation between the stimuli and the
%response, and sets this as the linear filter for the LN model.

function filter = getFilter(stim, response, params)
numPts = size(stim, 2);

% loop across all epochs to compute filter
for ii = 1:size(response, 1)
    %responseSingle = zeros(1, numPts * 2 - 1);  
    %stimSingle = responseSingle;
    
	%responseSingle(1,1:numPts) = response(ii, :) - mean(response(ii, :));
	%stimSingle(1,1:numPts) = stim(ii, :);
     
    responseSingle = response(ii, :) - mean(response(ii, :));
    stimSingle = stim(ii, :);
    
    dataFFT = fft(responseSingle);
    stmFFT = fft(stimSingle);
    
    if ii == 1
        filterFFT = conj(stmFFT) .* dataFFT; 
    else
        filterFFT = filterFFT + conj(stmFFT) .* dataFFT;
    end
end
filterFFT = filterFFT / size(response, 1);

%Deal with Nyquist frequency
filterFFT = filterFFT / numPts;
freqStep = 1 / (numPts * params.samplingInterval);

%Remove frequencies higher than specified cutoff
maxFreq = round(params.frequencyCutoff / freqStep);
filterFFT(maxFreq:numPts - maxFreq) = 0;
filterFFT(1) = 0;

filter = real(ifft(filterFFT));
filter(params.staPts:length(filter) - params.staPts) = 0;

%Normalize the filter (such that it becomes an impulse response rotated
%about the x-axis)
filter = filter / max(abs(filter));

%We remove the zeros resulting from deriving the filters with linear
%convolution (i.e. zero padding of stim and response before multiplying in
%frequency domain) or zeros resulting from params.staPts setting.
filter(filter == 0) = [];

%Save filter as two portions - the part that contains "positive time" (after
%stimulus presentation) and the one with "negative time" (before stimulus
%presentation). Don't save any of the zeros that result from the padding
%stage.
%Save the negative time portion as half as short as the positive time
%portion.

%TO DO: Make this portion tunable.
dividingTimeLength = round(length(filter) / 8);
positiveTimeEnd = 2 * dividingTimeLength;
negativeTimeStart = length(filter) - dividingTimeLength;

if strcmp(params.filterType, 'half')
    filter = struct('positiveTime', filter(1:positiveTimeEnd));
else
    filter = struct('positiveTime', filter(1:positiveTimeEnd), ...
        'negativeTime', filter(negativeTimeStart + 1:end));
end

end

