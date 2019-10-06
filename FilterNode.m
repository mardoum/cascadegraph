classdef FilterNode < ModelNode
    
    properties
        filter
        hasAnticausalHalf
    end
    
    methods
        
        function obj = FilterNode(filter, hasAnticausalHalf)  % constructor
            if nargin > 0
                assert(isvector(filter) && ismember(hasAnticausalHalf,[0,1]), ...
                    'error: filter and hasAnticausalHalf must be passed to constructor together');
                obj.filter = filter;
                obj.hasAnticausalHalf = hasAnticausalHalf;
            end
        end
        
        function out = process(obj, stim)
            if size(stim,1) > size(stim,2)
                stim = stim';
            end
            out = convolveFilterWithStim(obj.filter, stim, obj.hasAnticausalHalf);
        end
        
    end
    
    methods (Access = protected)
        
        function out = returnOutput(obj, in)
            validateattributes(in, {'cell'}, {'numel', 1});
            out = obj.process(in{1});
        end
        
    end
    
end