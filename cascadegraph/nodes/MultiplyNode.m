classdef MultiplyNode < ModelNode
    % A MultiplyNode multiplies its inputs element-wise.
    
    methods (Static)
        
        function out = process(in)
            product = in{1};
            if length(in) > 1
                for i = 2:length(in)
                    assert(isequal(size(in{i}), size(in{1})), ...
                        'Dimensions of all inputs must be equal')
                    product = product .* in{i};
                end
            end
            out = product;
        end
        
    end
    
    methods (Access = protected)
        
        function out = returnOutput(obj, in)
            assert(isa(in, 'cell'), 'Input class should be cell array');
            out = obj.process(in);
        end
        
    end
    
end