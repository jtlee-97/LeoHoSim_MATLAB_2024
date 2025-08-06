% =================================================================
% Winner LAB, Ajou University
% Distance-based HO Parameter Optimization Protocol Code
% Prototype    : GET_AGGAIN.m
% Type         : MATLAB function Code
% Author       : Jongtae Lee
% Revision     : v1.0   2024.06.04
% Modified     : 2024.06.04
% =================================================================

%% Get Antenna Gain
function A = GET_AGGAIN(theta,maxgain,f,aperture)
    c = 3 * 10^8;
    
    A = zeros(size(theta));  % Initialize the output array
    
    for i = 1:numel(theta)
        ka = 2 * pi * f / c * aperture / 2;
        z = ka * sind(theta(i));
        J = besselj(1, z);
        Y = 4 * abs(J / z)^2;
        
        if theta(i) == 0
            Y = 1;
        end
        
        A(i) = 10 * log10(Y / 1) + maxgain;
    end
end