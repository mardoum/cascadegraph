classdef DataNode < ModelNode
    % A DataNode stores data in the computation graph and returns the data
    % unaltered when queried.
    
    properties
        data
    end
    
    methods
       
        function obj = DataNode(data)
            if nargin > 0
                obj.data = data;
            end
        end
        
    end
    
    methods (Access = protected)
        
        function out = returnOutput(obj)
            assert(obj.upstream.count == 0, 'Terminal node type. DataNode should not have parent');
            out = obj.data;
        end
        
    end
    
end