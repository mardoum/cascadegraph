classdef (Abstract) HyperNode < ParameterizedNode
    % A HyperNode is a ParameterizedNode that stores a graph of other ModelNodes
    % for the purpose of jointly optimizing multiple nodes in the graph using
    % methods of ParameterizedNode.
    
    properties (Dependent)
        subnodes            % structure containing sub-nodes
    end
    
    properties (Access = protected)        
        subnodesProtected   % persistent, protected sub-nodes for optimization
    end
    
    methods
        
        function obj = HyperNode(varargin)
            obj@ParameterizedNode(varargin{:});
            obj.subnodesProtected = obj.subnodes;
        end
        
        function subnodes = get.subnodes(obj)
            subnodes = constructGraph(obj);
        end
        
    end
    
    methods (Abstract)
        
        constructGraph(obj);
        
    end
    
end