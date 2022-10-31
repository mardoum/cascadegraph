classdef NegativeNode < ModelNode
    % Multiplies input by -1.
    
    methods (Static)
        
        function out = process(in)
            out = cellfun(@(x) -x, in, 'UniformOutput', false);
        end
        
    end
    
    methods (Access = protected)
        
        function out = returnOutput(obj, in)
            assert(isa(in, 'cell'), 'Input class should be cell array');
            out = obj.process(in);
        end
        
    end
    
end