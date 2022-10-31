classdef RodLinearNode < ParameterizedNode
    % Linear model of rod photoreceptor.
    
    properties
        % Free params
        scFact              % Scaling Factor
        tauR                % Rising Phase Time Constant
        tauD                % Dampening Time Constant
        
        % Fixed params
        darkCurrent
        
        % needed if returnOutput will be called during recursive traversal of node chain
        dt_stored           % time step 
    end
    
    properties (Constant)
        freeParamNames = {'scFact', 'tauR', 'tauD'};
    end
    
    methods
        
        function obj = RodLinearNode(varargin)
            obj@ParameterizedNode(varargin{:});
        end

        function prediction = processTempParams(obj, params, stim, dt)
            % Use input free params and stored fixed params
            stim = stim';
            t = ((1:size(stim, 2)) * dt)';
            filter = params.scFact .* (((t./params.tauR).^3) ./ (1+((t./params.tauR).^3))) .* ...
                exp(-((t./params.tauD)));
            prediction = real(ifft(fft(stim) .* fft(filter))) - obj.darkCurrent;
            prediction = prediction';
        end
        
    end
    
    methods (Access = protected)
        
        function out = returnOutput(obj, in)
            assert(~isempty(obj.dt_stored), ...
                'RodLinearNode.returnOutput() requires dt_stored property to be set')
            out = obj.process(in, obj.dt_stored);
        end
        
    end
    
end