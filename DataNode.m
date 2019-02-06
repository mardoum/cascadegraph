classdef DataNode < ModelNode
    
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
            out = obj.data;
        end
        
    end
    
end