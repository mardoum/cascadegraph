classdef SumNode < ModelNode
    % A SumNode sums its inputs.
    
    methods (Static)
        
        function out = process(in)
            sum = in{1};
            if length(in) > 1
                for ii = 2:length(in)
                    assert(isequal(size(in{ii}), size(in{1})), 'Dimensions of all input vectors must be equal')
                    sum = sum + in{ii};
                end
            end
            out = sum;
        end
        
    end
    
    methods (Access = protected)
        
        function out = returnOutput(obj, in)
            assert(isa(in, 'cell'), 'Input class should be cell array');
            out = obj.process(in);
        end
        
    end
    
end