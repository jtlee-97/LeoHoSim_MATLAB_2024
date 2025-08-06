% =================================================================
% Winner LAB, Ajou University
% Distance-based HO Parameter Optimization Protocol Code
% Prototype    : system_start.m
% Type         : MATLAB code
% Author       : Jongtae Lee
% Revision     : v2.1   2024.06.04
% Modified     : 2024.08.27
% =================================================================

%% SYSTEM_START Script
clear;
close all;
tic;

%% IMPORT THE FUNCTION CODE FILES
addpath(genpath('functions'));

%% SYSTEM PARAMETERS
run('system_parameter.m');  % system_parameter 실행

% k_rsrp 값 확인
if exist('k_rsrp', 'var')
    k_rsrp_str = sprintf('K%d', k_rsrp);  % 파일명에 들어갈 "~K(i)" 생성
else
    k_rsrp_str = '';  % k_rsrp 값이 없으면 추가하지 않음
end

% A: BHO (기존 핸드오버, 0dB margin, 0ms TTT)
% B: BHO (기존 핸드오버, 1dB margin, 100ms TTT)
% C: BHO (기존 핸드오버, 2dB margin, 256ms TTT)
% D: CHO (조건부 핸드오버, 0dB margin, 0ms TTT)
% E: CHO (조건부 핸드오버, 1dB margin, 100ms TTT)
% F: CHO (조건부 핸드오버, 2dB margin, 256ms TTT)
% G: DCHO (거리기반 상대조건식, 0m margin, 0ms TTT)
% H: DCHO (ttt인데 보류)
% I: DCHO (ttt인데 보류)
% J: DCHO (3GPP 거리기반 조건부)
% K: DCHO (최종 제안하는 궤도기반 방안)

% Initialize strategies and corresponding parameters
strategies = {
    'Strategy T A3', 0, 0, 4.5;
    % 'Strategy A', 0, 0;
    % 'Strategy B', 0, 0.2;
    % 'Strategy C', 2, 0;
    % % 'Strategy D', 2, 0.2;
    % 'Strategy D', [], [];
    % 'Strategy E', [], [];
    % 'Strategy F', [], [];
    % 'Strategy G', [], [];
};

for option = 1:size(strategies, 1)
    master_histories_list{option} = [];
    MASTER_SINR = zeros(EPISODE, length(UE_x));
    MASTER_RSRP = zeros(EPISODE, length(UE_x));
    MASTER_UHO = zeros(EPISODE, length(UE_x));
    MASTER_RLF = zeros(EPISODE, length(UE_x));
    MASTER_HO = zeros(EPISODE, length(UE_x));
    MASTER_RBs = zeros(EPISODE, length(UE_x));
    MASTER_HOPP = zeros(EPISODE, length(UE_x));  % HOPP 추가
    MASTER_ToS = [];  % 1차원 배열로 저장
    MASTER_RAW_SINR = zeros(length(TIMEVECTOR), length(UE_x));
    MASTER_RAW_RSRP = zeros(length(TIMEVECTOR), length(UE_x));

    % Extract current strategy name and parameters
    strategy_name = strategies{option, 1};
    current_Offset_A3 = strategies{option, 2};
    current_TTT = strategies{option, 3};

    % Loop through each UE_x position
    for ue_idx = 1:length(UE_x)
        uex = UE_x(ue_idx);
        uey = UE_y;

        % Output progress
        fprintf('Processing %s, UE position %d of %d\n', strategy_name, ue_idx, length(UE_x));

        % Run the system process for the current UE position and strategy
        [histories, episode_results, final_results, master_histories] = system_process(uex, uey, EPISODE, TIMEVECTOR, SITE_MOVE, SAMPLE_TIME, option, current_Offset_A3, current_TTT);
        master_histories_list{option} = [master_histories_list{option}; master_histories];

        % Loop through each episode to calculate and store results
        for episode_idx = 1:EPISODE
            total_sinr = 0;
            total_rsrp = 0;
            for t_idx = 1:length(TIMEVECTOR)
                total_sinr = total_sinr + episode_results(1, episode_idx).SINR(t_idx);
                total_rsrp = total_rsrp + episode_results(1, episode_idx).RSRP(t_idx);
            end

            % Calculate average SINR and store results
            avg_sinr = total_sinr / length(TIMEVECTOR);
            avg_rsrp = total_rsrp / length(TIMEVECTOR);
            MASTER_SINR(episode_idx, ue_idx) = avg_sinr;
            MASTER_RSRP(episode_idx, ue_idx) = avg_rsrp;
            MASTER_UHO(episode_idx, ue_idx) = episode_results(1, episode_idx).UHO;
            MASTER_RLF(episode_idx, ue_idx) = episode_results(1, episode_idx).RLF;
            MASTER_HO(episode_idx, ue_idx) = episode_results(1, episode_idx).HO;
            MASTER_RBs(episode_idx, ue_idx) = episode_results(1, episode_idx).RBs;
            MASTER_HOPP(episode_idx, ue_idx) = episode_results(1, episode_idx).HOPP;

            % Read the ToS for the current episode
            tos_values = episode_results(1, episode_idx).ToS;
            if isempty(tos_values)
                tos_values = 0;
            end
            if size(tos_values, 1) > 1
                tos_values = tos_values';
            end
            MASTER_ToS = [MASTER_ToS, tos_values];
        end

        % Store final SINR values
        avg_final_tt_sinr = mean(final_results.final_tt_SINR, 2);
        avg_final_tt_rsrp = mean(final_results.final_tt_RSRP, 2);
        MASTER_RAW_SINR(:, ue_idx) = avg_final_tt_sinr;
        MASTER_RAW_RSRP(:, ue_idx) = avg_final_tt_rsrp;
        MASTER_RLF_SUM_TEST = sum(MASTER_RLF);
    end

    % Save MASTER structure arrays for the current strategy
    folderName = 'MasterResults';
    if ~exist(folderName, 'dir')
        mkdir(folderName);
    end

    % 파일명에 k_rsrp 값 추가하여 저장
    matFileName = fullfile(folderName, [Scenario_, '_MASTER_RESULTS_', strategy_name, '_', k_rsrp_str, '_', fading, '.mat']);
    save(matFileName, 'MASTER_SINR', 'MASTER_RSRP', 'MASTER_UHO', 'MASTER_RLF', 'MASTER_HO', 'MASTER_HOPP', 'MASTER_RAW_SINR', 'MASTER_RAW_RSRP', 'MASTER_ToS', 'MASTER_RBs');
end

toc;
