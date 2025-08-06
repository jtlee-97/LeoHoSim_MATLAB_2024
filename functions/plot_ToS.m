% =================================================================
% Winner LAB, Ajou University
% Handover Ping-Pong Class Definition
% Prototype    : plot_ToS.m
% Type         : MATLAB Figure Code
% Author       : Jongtae Lee
% Revision     : v1.0   2024.06.04
% Modified     : 2024.06.04
% =================================================================

function plot_ToS(histories, episode_results, sample_time)
    num_episodes = size(histories, 2);
    num_ues = size(histories, 1);

    total_ToS = containers.Map('KeyType', 'double', 'ValueType', 'double');
    
    for i = 1:num_ues
        for j = 1:num_episodes
            history = histories(i, j);
            history = history.calculate_ToS(sample_time);
            tos_map = history.ToS;
            keys = tos_map.keys;
            for k = 1:numel(keys)
                key = keys{k};
                if isKey(total_ToS, key)
                    total_ToS(key) = total_ToS(key) + tos_map(key);
                else
                    total_ToS(key) = tos_map(key);
                end
            end
        end
    end

    % Plot the ToS values
    figure;
    keys = cell2mat(total_ToS.keys);
    values = cell2mat(total_ToS.values);
    bar(keys, values);
    xlabel('Serving Cell Index');
    ylabel('Total Time of Stay (seconds)');
    title('Time of Stay (ToS) per Serving Cell');
    grid on;
end

