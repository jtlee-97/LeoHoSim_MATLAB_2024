% =================================================================
% Winner LAB, Ajou University
% Distance-based HO Parameter Optimization Protocol Code
% Prototype    : class_FinalResult.m
% Type         : MATLAB Class
% Author       : Jongtae Lee
% Revision     : v1.0   2024.06.04
% Modified     : 2024.06.04
% =================================================================

classdef class_FinalResult
    properties
        final_tt_SINR
        final_SINR
        final_avg_SINR
        final_RSRP
        final_tt_RSRP
        final_avg_RSRP
        final_avg_HO
        final_avg_HOPP
        final_avg_RLF
        final_avg_ToS
        final_tt_ToS
        %final_avg_percent_error_ToS
        final_avg_UHO
        final_avg_Delay;
        final_avg_PACKET_LOSS;
    end

    methods
        function obj = calculate_final_average(obj, episode_results)
            num_episodes = numel(episode_results);
            num_timevectors = length(episode_results(1).SINR);
            total_SINR = [];
            total_RSRP = [];
            total_ToS = [];
            total_HO = 0;
            total_HOPP = 0;
            total_RLF = 0;
            total_ToS = 0;
            total_percent_error_ToS = 0;
            total_UHO = 0;
            obj.final_avg_Delay = mean([episode_results.avg_Delay]);
            obj.final_avg_PACKET_LOSS = mean([episode_results.avg_PACKET_LOSS]);

            % Collect all SINR values across episodes
            for i = 1:num_episodes
                total_SINR = [total_SINR, episode_results(i).SINR]; % Concatenate horizontally
                total_RSRP = [total_RSRP, episode_results(i).RSRP];
                total_ToS = [total_ToS, episode_results(i).actual_ToS]; % Concatenate horizontally
                total_HO = total_HO + episode_results(i).HO;
                total_HOPP = total_HOPP + episode_results(i).HOPP;
                total_RLF = total_RLF + episode_results(i).RLF;
                total_ToS = total_ToS + episode_results(i).avg_ToS;
                %total_percent_error_ToS = total_percent_error_ToS + episode_results(i).percent_error_ToS;
                total_UHO = total_UHO + episode_results(i).UHO;
            end

            % Calculate the average SINR for each TIMEVECTOR
            avg_SINR_per_timevector = mean(total_SINR, 2);
            avg_RSRP_per_timevector = mean(total_RSRP, 2);
            avg_ToS_per_timevector = mean(total_ToS, 2);

            % Calculate the final average SINR
            obj.final_tt_SINR = total_SINR;
            obj.final_tt_RSRP = total_RSRP;
            obj.final_SINR = avg_SINR_per_timevector;
            obj.final_RSRP = avg_RSRP_per_timevector;
            obj.final_tt_ToS = total_ToS;
            obj.final_avg_SINR = mean(avg_SINR_per_timevector);
            obj.final_avg_RSRP = mean(avg_RSRP_per_timevector);
            obj.final_avg_HO = total_HO / num_episodes;
            obj.final_avg_HOPP = total_HOPP / num_episodes;
            obj.final_avg_RLF = total_RLF / num_episodes;
            obj.final_avg_ToS = total_ToS / num_episodes;
            %obj.final_avg_percent_error_ToS = total_percent_error_ToS / num_episodes;
            obj.final_avg_UHO = total_UHO / num_episodes;
        end
    end
end
