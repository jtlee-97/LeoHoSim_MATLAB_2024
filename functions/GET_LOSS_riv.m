% =================================================================
% Winner LAB, Ajou University
% Distance-based HO Parameter Optimization Protocol Code
% Prototype    : GET_LOSS_riv.m
% Type         : MATLAB function Code
% Author       : Jongtae Lee
% Revision     : v2.0   2024.06.04
% Modified     : 2024.12.03
% =================================================================

%% Loss function (Modified)
function loss_result = GET_LOSS_riv(freq, dist_array, elev_array)
    loss_result = zeros(size(dist_array));  % Initialize the output array
    
    for i = 1:numel(dist_array)
        fs = freespacePL(freq, dist_array(i)); % Free Space Path Loss
        los_prob_val = los_prob(elev_array(i)); % LoS Probability
        los_sdcl = sd_cl(elev_array(i)); % Shadowing and Clutter Loss
        
        % Random selection based on LoS probability
        if rand < (los_prob_val / 100)
            loss_result(i) = fs + los_sdcl(1); % LoS selected
        else
            loss_result(i) = fs + los_sdcl(2); % NLoS selected
        end
    end
end

%% Basic Path Loss (Modified)
function x = basicPL(f, d, e)
    fs = freespacePL(f, d);
    los_prob_val = los_prob(e);
    los_sdcl = sd_cl(e);
    
    % Random selection based on LoS probability
    if rand < (los_prob_val / 100)
        x = fs + los_sdcl(1); % LoS selected
    else
        x = fs + los_sdcl(2); % NLoS selected
    end
end

%% Free Space Path Loss
function x = freespacePL(f, d)
    c = 299792458; % Speed of light in m/s
    x = 20 * log10(f) + 20 * log10(d) + 20 * log10(4 * pi / c);
end

%% Shadowing and Clutter Loss
function x = sd_cl(e)
    idx = max(1, min(round(e / 10), 9)); % Ensure idx is within bounds

    % Dense Urban Environment Parameters
    los_sw = [3.5 3.4 2.9 3 3.1 2.7 2.5 2.3 1.2]; % LoS Shadow Fading (σ_SF)
    nlos_sw = [15.5 13.9 12.4 11.7 10.6 10.5 10.1 9.2 9.2]; % NLoS Shadow Fading (σ_SF)
    nlos_cl = [34.3 30.9 29 27.7 26.8 26.2 25.8 25.5 25.5]; % NLoS Clutter Loss

    % LoS and NLoS loss components
    a = los_sw(idx) * randn(1, 1); % LoS Shadow Fading
    b = nlos_sw(idx) * randn(1, 1) + nlos_cl(idx); % NLoS Shadow Fading + Clutter Loss
    x = [a b]; % Return both LoS and NLoS losses
end

%% LoS Probability
function x = los_prob(e)
    idx = max(1, min(round(e / 10), 9)); % Ensure idx is within bounds
    los_prob_value = [28.2 33.1 39.8 46.8 53.7 61.2 73.8 82.0 98.1]; % DenseUrban LoS Probability
    x = los_prob_value(idx);
end
