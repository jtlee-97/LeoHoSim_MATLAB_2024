% =================================================================
% Winner LAB, Ajou University
% Distance-based HO Parameter Optimization Protocol Code
% Prototype    : GET_DIS_ML.m
% Type         : MATLAB function Code
% Author       : Jongtae Lee
% Revision     : v1.0   2024.06.04
% Modified     : 2024.06.04
% =================================================================

% ML 거리 계산
function ML = GET_DIS_ML(BORE_X, BORE_Y, UE_LOC_X, UE_LOC_Y)
    num_bores = length(BORE_X);
    ML = zeros(1, num_bores);
    
    for i = 1:num_bores
        ML(i) = sqrt((BORE_X(i) - UE_LOC_X)^2 + (BORE_Y(i) - UE_LOC_Y)^2);
    end
end
