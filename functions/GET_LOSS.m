% =================================================================
% Winner LAB, Ajou University
% Distance-based HO Parameter Optimization Protocol Code
% Prototype    : GET_LOSS.m
% Type         : MATLAB function Code
% Author       : Jongtae Lee
% Revision     : v1.0   2024.06.04
% Modified     : 2024.06.04
% =================================================================

%% Loss function
function loss_result = GET_LOSS(freq, dist_array, elev_array)
    loss_result = zeros(size(dist_array));  % Initialize the output array
    
    for i = 1:numel(dist_array)
        fs = freespacePL(freq, dist_array(i));
        los_prob_val = los_prob(elev_array(i));
        los_sdcl = sd_cl(elev_array(i));
        loss_result(i) = (los_prob_val / 100) * (fs + los_sdcl(1)) + ((100 - los_prob_val) / 100) * (fs + los_sdcl(2));
    end
end

%% Basic Path Loss
function x = basicPL(f, d, e)
    fs = freespacePL(f, d);
    los_prob_val = los_prob(e);
    los_sdcl = sd_cl(e);
    x = (los_prob_val / 100) * (fs + los_sdcl(1)) + ((100 - los_prob_val) / 100) * (fs + los_sdcl(2));
end

%% Free Space Path Loss
% Parameters: [frequency, distance]
function x = freespacePL(f, d)
    c = 299792458;
    x = 20 * log10(f) + 20 * log10(d) + 20 * log10(4 * pi / c);
end

%% Shadowing and Clutter Loss
function x = sd_cl(e)
    idx = max(1, min(round(e / 10), 9)); % Ensure idx is within bounds

    % % RURAL, SUBURBAN
    los_sw = [1.79 1.14 1.14 0.92 1.42 1.56 0.85 0.72 0.72];
    nlos_sw = [8.93 9.08 8.78 10.25 10.56 10.74 10.17 11.52 11.52];
    nlos_cl = [19.52 18.17 18.42 18.28 18.63 17.68 16.50 16.30 16.30];

    % URBAN
    % los_sw = [4 4 4 4 4 4 4 4 4];
    % nlos_sw = [6 6 6 6 6 6 6 6 6];
    % nlos_cl = [34.3 30.9 29 27.7 26.8 26.2 25.8 25.5 25.5];

    % DENSE URBAN
    % los_sw = [3.5 3.4 2.9 3 3.1 2.7 2.5 2.3 1.2];
    % nlos_sw = [15.5 13.9 12.4 11.7 10.6 10.5 10.1 9.2 9.2];
    % nlos_cl = [34.3 30.9 29 27.7 26.8 26.2 25.8 25.5 25.5];

    % a = (-los_sw(idx)) + (2 * los_sw(idx)) * rand(1, 1);
    % b = (-nlos_sw(idx)) + (2 * nlos_sw(idx)) * rand(1, 1) + nlos_cl(idx);
    % x = [a b];

    % 'los_sw'는 LoS 상황에서의 표준편차(σ_SF), 'nlos_sw'는 NLoS 상황에서의 표준편차(σ_SF), 'nlos_cl'은 NLoS에서의 clutter loss
    a = los_sw(idx) * randn(1, 1);  % LoS 상황에서 Shadow Fading 값을 생성 (정규 분포)
    b = nlos_sw(idx) * randn(1, 1) + nlos_cl(idx);  % NLoS 상황에서 Shadow Fading + Clutter Loss
    x = [a b];  % LoS와 NLoS Shadow Fading 값

end

%% LoS Probability
% Parameter: [elevation]
function x = los_prob(e)
    idx = max(1, min(round(e / 10), 9)); % Ensure idx is within bounds
    los_prob_value = [78.2 86.9 91.9 92.9 93.5 94 94.9 95.2 99.8]; % Rural
    % los_prob_value = [24.6 38.6 49.3 61.3 72.6 80.5 91.9 96.8 99.2]; % Urban
    % los_prob_value = [28.2 33.1 39.8 46.8 53.7 61.2 73.8 82.0 98.1]; % DenseUrban
    x = los_prob_value(idx);
end
