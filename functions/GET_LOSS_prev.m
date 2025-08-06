% =================================================================
% Winner LAB, Ajou University
% Distance-based HO Parameter Optimization Protocol Code
% Prototype    : GET_LOSS_prev.m
% Type         : MATLAB function Code
% Author       : Jongtae Lee
% Revision     : v1.0   2024.06.04
% Modified     : 2024.06.04
% =================================================================

%% Loss function
function loss_result = GET_LOSS_prev(freq, dist_array, elev_array)
    loss_result = zeros(size(dist_array));  % Initialize the output array
    
    for i = 1:numel(dist_array)
        loss_result(i) = basicPL(freq, dist_array(i), elev_array(i));
    end
end

%% Basic Path Loss
function x = basicPL(f, d, e)
    fs = freespacePL(f, d);
    los_sdcl = sd_cl(e);
    x = (los_prob(e) / 100) * (fs + los_sdcl(1)) + ((100 - los_prob(e)) / 100) * (fs + los_sdcl(2));
end

%% Free Space Path Loss
% Parameters: [frequency, distance]
function x = freespacePL(f, d)
    c = 299792458;
    x = 20 * log10(f) + 20 * log10(d) + 20 * log10(4 * pi / c);
end

%% Shadowing and Clutter Loss
function x = sd_cl(e)
    idx = round(e / 10);
    %fprintf('idx: %d\n', idx); % Add this line to print the value of idx
    los_sw = [1.79 1.14 1.14 0.92 1.42 1.56 0.85 0.72 0.72];
    nlos_sw = [8.93 9.08 8.78 10.25 10.56 10.74 10.17 11.52 11.52];
    nlos_cl = [19.52 18.17 18.42 18.28 18.63 17.68 16.50 16.30 16.30];
    
    a = (-los_sw(idx)) + (2 * los_sw(idx)) * rand(1, 1);
    b = (-nlos_sw(idx)) + (2 * nlos_sw(idx)) * rand(1, 1) + nlos_cl(idx);
    x = [a b];
end

%% LoS Probability
% Parameter: [elevation]
function x = los_prob(e)
    idx = round(e / 10);
    los_prob_value = [78.2 86.9 91.9 92.9 93.5 94 94.9 95.2 99.8];
    x = los_prob_value(idx);
end

