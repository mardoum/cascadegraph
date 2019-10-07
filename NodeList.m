classdef NodeList < handle
    % A NodeList is an ArrayList-like data structure meant to store a list of
    % ModelNode instances.
    %
    % Modified from Symphony's ArrayList.m
   
    properties
        items
    end
    
    properties (SetAccess = private)
        count
    end
    
    properties (Access = private)
        itemcount
    end
    
    methods
        
        function obj = NodeList()            
            obj.items = {};
            obj.itemcount = 0;
        end
        
        function add(obj, item)
            obj.itemcount = obj.itemcount + 1;
            obj.items{obj.itemcount} = item;
        end
        
        function addRange(obj, list)
            obj.items = [obj.items(1:obj.itemcount) list.items];
            obj.itemcount = obj.itemcount + list.itemcount;
        end
        
        function remove(obj, item)
            i = obj.indexOf(item);
            obj.removeAt(i);
        end
        
        function removeAt(obj, index)
            obj.items(index) = [];
            obj.itemcount = obj.itemcount - 1;
        end
        
        function i = item(obj, index, value)
            if index < 0 || index >= obj.itemcount
                error('Out of range')
            end
            
            if nargin > 2
                obj.items{index} = value;
            end
            
            i = obj.items{index};
        end
        
        function c = get.count(obj)
            c = obj.itemcount;
        end
        
        function clear(obj)
            obj.items = {};
            obj.itemcount = 0;
        end
        
        function i = indexOf(obj, item)
            i = find(cellfun(@(c)isequal(c, item), obj.items), 1, 'first');
            
            if isempty(i)
                i = -1;
            end
        end
        
        function b = contains(obj, item)
            b = obj.indexOf(item) ~= -1;
        end
        
        function enum = getEnumerator(obj)
            enum = Enumerator(@MoveNext);
            enum.State = 0;
            
            function b = MoveNext()
                enum.Current = [];
                
                if enum.State + 1 > obj.itemcount
                    b = false;
                    return;
                end
                
                enum.Current = obj.items{enum.State + 1};
                enum.State = enum.State + 1;
                b = true;
            end
        end
        
    end
    
end