classdef ParamLnNode < ParameterizedNode
    
    properties
        % free params
        numFilt             % scaling factor
        tauR                % rising phase time constant
        tauD                % dampening time constant
        tauP                % period
        phi                 % phase
        nonlinScale
        nonlinMean
        nonlinSD
        nonlinOffset
        
        % needed if returnOutput will be called
        dt_stored           % time step 
    end
    
    properties (Constant)
        freeParamNames = {'numFilt', 'tauR', 'tauD', 'tauP', 'phi', ...
            'nonlinScale', 'nonlinMean', 'nonlinSD', 'nonlinOffset'};
    end
    
    methods
        
        function obj = ParamLnNode(varargin)
            obj@ParameterizedNode(varargin{:});
        end
        
    end
    
    methods (Static)
        
        function prediction = processTempParams(params, stim, dt)
            % run with input free params, using instance properties for fixed params
            if size(stim,1) < size(stim,2)
                stim = stim';
                transpose = true;
            else
                transpose = false;
            end
            
            t = ((1:length(stim)) * dt)';
            filter = (((t./params.tauR).^params.numFilt)./(1+((t./params.tauR).^params.numFilt))) ...
                .* exp(-((t./params.tauD))) .* cos(((2.*pi.*t)./params.tauP)+(2*pi*params.phi/360));
            filter = filter/max(abs([max(filter) min(filter)]));

            generator = real(ifft(fft(stim) .* fft(filter)));
            
            prediction = params.nonlinScale * ...
                normcdf(generator, params.nonlinMean, abs(params.nonlinSD)) + params.nonlinOffset;
            
            if transpose
                prediction = prediction';
            end
        end
        
    end
    
    methods (Access = protected)
        
        function out = returnOutput(obj, in)
            assert(~isempty(obj.dt_stored), ...
                'ParamFilterNode.returnOutput() requires dt_stored property to be set')
            out = obj.process(in, obj.dt_stored);
        end
        
    end
    
end