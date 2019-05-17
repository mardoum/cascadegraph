classdef ParameterizedNode < ModelNode
    
    properties (Abstract, Constant)
        freeParamNames  % list of free parameter property names
    end
    
    methods
        
        function obj = ParameterizedNode(freeParams, otherParams)  % constructor
            if nargin > 0
                writeFreeParams(obj, freeParams)
            end
            if nargin > 1
                assert(isstruct(otherParams), 'Input non-free params must be in a struct')
                otherParamNames = fieldnames(otherParams);
                for ii = 1:length(otherParamNames)
                    obj.(otherParamNames{ii}) = otherParams.(otherParamNames{ii});
                end
            end
        end
        
        function writeFreeParams(obj, params)
            if isstruct(params)
                params = paramStructToVec(params);
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
            for ii = length(params)
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
    
end