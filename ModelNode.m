classdef (Abstract) ModelNode < handle
    % A ModelNode is a node in a directed computation graph. The ModelNode class
    % is abstract and contains methods used to recursively traverse the
    % computation graph. Every ModelNode stores a list, called upstream, of
    % incoming neighbor nodes (this list can be empty).
    %
    % A ModelNode graph should be acyclic. During graph traversal, data are
    % passed from upstream to downstream nodes in a cell array, where each entry
    % contains input from one parent.
    %
    % Subclasses of ModelNode must define a method, called returnOutput(), to
    % return output when the node is queried during graph traversal. 
    
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
            % Recursive method to traverse computation graph
            if node.upstream.count <= 0
                out = node.returnOutput();
            else
                in = cell(node.upstream.count, 1);
                for i = 1:node.upstream.count
                    in{i} = processParents(node.upstream.items{i});
                    % if 1x1 cell array, unpack:
                    if (isa(in{i}, 'cell') && length(in{i}) == 1) 
                        in{i} = in{i}{1};
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