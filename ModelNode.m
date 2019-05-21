classdef ModelNode < handle
    
    properties
        upstream
    end
    
    properties (Dependent)
        numUpstream
    end
    
    methods
        
        function out = runWithUpstream(obj)
            out = runNodeAndUpstream(obj);
        end
        
        function val = get.numUpstream(obj)
            val = getNumUpstreamOf(obj);
        end
        
        function printWithUpstream(obj)
            disp('-----------------------------------------');
            disp('Current and upstream nodes:'); disp(' ')
            printNodeWithUpstream(obj);
        end
        
    end
    
    methods (Access = protected)
        
        function out = runNodeAndUpstream(node)
            if isempty(node.upstream)
                out = node.returnOutput();
            else
                in = runNodeAndUpstream(node.upstream);
                out = node.returnOutput(in);
            end
        end
        
        function out = getNumUpstreamOf(node)
            if isempty(node.upstream)
                out = 0;
            else
                out = 1 + getNumUpstreamOf(node.upstream);
            end
        end
        
        function printNodeWithUpstream(node)
            if isempty(node.upstream)
                disp(node)
            else
                printNodeWithUpstream(node.upstream);
                disp('  |')
                disp('  |')
                disp('  V')
                disp(node)
            end
        end
        
    end
    
    methods (Abstract, Access = protected)
        
        returnOutput(in)
        
    end
 
end