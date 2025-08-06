% =================================================================
% Winner LAB, Ajou University
% Distance-based HO Parameter Optimization Protocol Code
% Prototype    : GET_UV_ELEV.m
% Type         : MATLAB function Code
% Author       : Jongtae Lee
% Revision     : v1.0   2024.06.04
% Modified     : 2024.06.04
% =================================================================

function elevation = GET_UV_ELEV(slant_dis, sat_h)
    Earth_rad = 63710000; % 지구 반지름 (미터 단위)
    elevation = rad2deg(asin((sat_h.^2+2.*sat_h.*Earth_rad-(slant_dis.^2))./(2.*slant_dis.*Earth_rad)));
end