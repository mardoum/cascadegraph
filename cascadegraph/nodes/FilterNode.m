classdef FilterNode < ModelNode
    % Temporal filter described by vector in time domain.
    
    properties
        filter              % vector in time domain
        hasAnticausalHalf   % boolean, true if filter contains structure on both sides of t=0.
    end
    
    methods
        
        function obj = FilterNode(filter, hasAnticausalHalf)
            if nargin > 0
                assert(isvector(filter) && ismember(hasAnticausalHalf,[0,1]), ...
                    'error: filter and hasAnticausalHalf must be passed to constructor together');
                obj.filter = filter;
                obj.hasAnticausalHalf = hasAnticausalHalf;
            end
        end
        
        function out = process(obj, stim)
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