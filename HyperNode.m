classdef (Abstract) HyperNode < ParameterizedNode
    % A HyperNode is a ParameterizedNode that stores a graph of other nodes
    % (sub-nodes). It is used when sub-node parameters are handled outside the
    % scope of the individual sub-nodes, such as when multiple instances of a
    % particular node type are controlled by the same parameters, or when
    % multiple nodes are optimized jointly. The sub-nodes and their parameters
    % are described within the scope of the HyperNode.
    %
    % Subclasses of HyperNode must: 
    %   - store as properties all parameters necessary to define the parameters
    %     of contained nodes.
    %   - have a subnodes() method that builds the contained graph and returns
    %     comprised nodes in a struct.
    
    properties (Access = protected)        
        % subnodesProtected is a protected persistent copy of the contained
        % graph for convenience during optimization. It should *almost never* be
        % referenced. Use subnodes() method to get a current copy of the
        % contained graph defined by stored parameters.
        
        subnodesProtected
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