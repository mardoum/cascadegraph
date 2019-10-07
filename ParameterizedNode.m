classdef (Abstract) ParameterizedNode < ModelNode
    % A ParameterizedNode is a ModelNode whose methods require that one or more
    % parameters be defined. The ParameterizedNode class is abstract and
    % contains methods used to manage and optimize free parameters. 
    %
    % Subclasses of ParameterizedNode must:
    %   - store each free parameter as a property 
    %   - define a list of names of free parameters (called freeParamNames). 
    %   - define a method to process external inputs using input parameters
    %     (called processTempParams(params, input)). These parameters need not
    %     match the parameters stored by a node instance as properties.
    
    properties (Abstract, Constant)
        freeParamNames  % list of free parameter property names
    end
    
    methods
        
        function obj = ParameterizedNode(varargin)
            % Inputs to constructor are optional
            % Usage: obj = ParameterizedNode(freeParams, otherParams)
            %   freeParams is a struct or vector with params in order of obj.freeParamNames
            %   otherParams is a struct
            assert(nargin < 3, 'Too many input arguments')
            if nargin > 0 && ~isempty(varargin{1})
                freeParams = varargin{1};
                writeFreeParams(obj, freeParams)
            end
            if nargin > 1
                otherParams = varargin{2};
                assert(isstruct(otherParams), 'Input non-free params must be in a struct')
                otherParamNames = fieldnames(otherParams);
                for ii = 1:length(otherParamNames)
                    obj.(otherParamNames{ii}) = otherParams.(otherParamNames{ii});
                end
            end
        end
        
        function prediction = process(obj, input, dt)
            % Process input using parameters stored as instance properties
            params = obj.getFreeParams('struct');
            assert(~any(structfun(@isempty, params)), ...
                'Execution failed because of empty properties')
            if nargin > 2
                prediction = obj.processTempParams(params, input, dt);
            else
                prediction = obj.processTempParams(params, input);
            end
        end
        
        function fitParams = optimizeParams(obj, params0, input, target, dt, options)
            if nargin > 5
                fitParams = fminsearch(@tryParams, params0, options);
            else
                fitParams = fminsearch(@tryParams, params0);
            end
            
            function error = tryParams(params)
                pstruct = obj.paramVecToStruct(params);
                prediction = obj.processTempParams(pstruct, input, dt);
                sqerrors = (target - prediction).^2;
                error = sum(sqerrors(:));
            end
            
            obj.writeFreeParams(fitParams)
        end
        
        function writeFreeParams(obj, params)
            if isstruct(params)
                params = obj.paramStructToVec(params);
            end
            assert(length(params) == length(obj.freeParamNames), ...
                'Length of input vector does not equal number of free parameters')
            for ii = 1:length(params)
                obj.(obj.freeParamNames{ii}) = params(ii);
            end
        end
        
        function params = getFreeParams(obj, outputClass)
            params = zeros(length(obj.freeParamNames), 1);
            for ii = 1:length(obj.freeParamNames)
                params(ii) = obj.(obj.freeParamNames{ii});
            end
            if nargin > 1 && strcmp(outputClass, 'struct')
                params = obj.paramVecToStruct(params);
            end
        end
       
        function paramStruct = paramVecToStruct(obj, params)
            assert(length(params) == length(obj.freeParamNames), ...
                'Length of input vector does not equal number of free parameters')
            for ii = 1:length(params)
                paramStruct.(obj.freeParamNames{ii}) = params(ii);
            end
        end
        
        function paramVec = paramStructToVec(obj, params)
            assert(length(fieldnames(params)) == length(obj.freeParamNames), ...
                'Length of input struct does not equal number of free parameters')
            paramVec = zeros(length(obj.freeParamNames), 1);
            for ii = 1:length(obj.freeParamNames)
                paramVec(ii) = params.(obj.freeParamNames{ii});
            end
        end
        
    end
    
    methods (Abstract)
        
        processTempParams(params, input)
        
    end
    
end