% =================================================================
% Winner LAB, Ajou University
% RLF Class Definition
% Prototype    : class_RLF.m
% Type         : MATLAB Class
% Author       : Jongtae Lee
% Revision     : v1.0   2024.06.04
% Modified     : 2024.06.04
% =================================================================

classdef class_RLF
    properties
        start_RLF_time;
        T310_check;
    end

    methods
        % RLF 객체 생성
        function obj = class_RLF(start_time)
            obj.start_RLF_time = start_time;
            obj.T310_check = 0;
        end

        % RLF 검사 초기화
        function obj = update_T310(obj, current_time)
            obj.T310_check = current_time - obj.start_RLF_time;
        end
    end
end
