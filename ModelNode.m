classdef (Abstract) ModelNode < handle
    % A ModelNode is a node in a directed computation graph. The ModelNode class
    % is abstract and contains methods used to recursively traverse the
    % computation graph. 
    %
    % A ModelNode graph should be acyclic. During graph traversal, input should
    % be passed between nodes in a cell arrays, where each cell contains input
    % from one parent.
    
    properties
        upstream NodeList   % List of parent nodes
    end
    
    methods
        
        function obj = ModelNode()
            obj.upstream = NodeList();
        end
        
        function out = processUpstream(obj)
            % Initiate graph traversal
            out = processParents(obj);
        end
        
    end
    
    methods (Access = protected)
        
        function out = processParents(node)
            if node.upstream.count < 1
                out = node.returnOutput();
            else
                in = cell(node.upstream.count, 1);
                for ii = 1:node.upstream.count
                    in{ii} = processParents(node.upstream.items{ii});
                    % if 1x1 cell array, unpack:
                    if (isa(in{ii}, 'cell') && length(in{ii}) == 1) 
                        in{ii} = in{ii}{1};
                    end
                end
                out = node.returnOutput(in);
            end
        end
        
    end
    
    methods (Abstract, Access = protected)
        
        returnOutput(in)
        
    end
 
end