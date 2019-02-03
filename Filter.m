classdef Filter < handle
	
    properties
		filter
        hasAnticausalHalf
    end

	methods
        
		function obj = Filter(filter, hasAnticausalHalf)  % constructor
			if nargin > 0
				assert(isvector(filter) && ismember(hasAnticausalHalf,[0,1]), ...
                    'error: filter and hasAnticausalHalf must be passed to constructor together');
                obj.filter = filter;
                obj.hasAnticausalHalf = hasAnticausalHalf;
			end
        end

		function out = process(obj, stim)
			out = convolveFilterWithStim(obj.filter, stim, obj.hhasAnticausalHalf);
		end

	end
end