classdef ModelNode < handle
    
    properties
        upstream NodeList
    end
    
    methods
        
        function obj = ModelNode()  % constructor
            obj.upstream = NodeList();
        end
        
        function out = processUpstream(obj)
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
                    % if 1x1 cell array, unpack
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