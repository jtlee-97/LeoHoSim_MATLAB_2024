% =================================================================
% Winner LAB, Ajou University
% Handover Ping-Pong Class Definition
% Prototype    : class_HOPP.m
% Type         : MATLAB Class
% Author       : Jongtae Lee
% Revision     : v1.0   2024.06.04
% Modified     : 2024.06.04
% =================================================================

classdef class_HOPP
    properties
        init_site;
        pp_start_time;
    end
    
    methods
        function obj = class_HOPP(init_site, pp_start_time)
            obj.init_site = init_site;
            obj.pp_start_time = pp_start_time;
        end
    end
end
