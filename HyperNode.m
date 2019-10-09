classdef (Abstract) HyperNode < ParameterizedNode
    % A HyperNode is a ParameterizedNode that stores a graph of other ModelNodes
    % for the purpose of jointly optimizing multiple nodes in the graph using
    % methods of ParameterizedNode.
    %
    % A subclass of HyperNode must: 
    %   - store as properties all parameters necessary to define the parameters
    %     of contained nodes
    %   - have a subnodes() method that returns the contained graph in a 
    %     structure.
    
    properties (Access = protected)        
        subnodesProtected   % persistent, protected sub-nodes for optimization
    end
    
    methods
        
        function obj = HyperNode(varargin)
            obj@ParameterizedNode(varargin{:});
            obj.subnodesProtected = obj.subnodes;
        end
        
    end
    
    methods (Abstract)
        
        subnodes(obj);
        
    end
    
end