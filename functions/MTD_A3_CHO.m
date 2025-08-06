% =================================================================
% Winner LAB, Ajou University
% Distance-based HO Parameter Optimization Protocol Code
% Prototype    : MTD_A3_CHO.m
% Type         : MATLAB function Code
% Author       : Jongtae Lee
% Revision     : v1.0   2024.06.04
% Modified     : 2024.06.04
% =================================================================

%% A3-based HO in EMC
function ue = MTD_A3_CHO(ue, sat, Offset_A3, TTT, current_time)
    handover = ue.handover;
    prep_delay = 3 * 0.002; % MR, HO CMD (RRC), RRC Complete
    % exec_delay = 3 * 0.002; % RACH 성공 100%

    % Entering conditions
    cond1_enter = ue.RSRP_dBm(ue.SERV_SITE_IDX) + Offset_A3 < ue.RSRP_dBm;
    cond2_t_enter = false;
    
    if handover.targ_idx > 0
        cond2_t_enter = ue.RSRP_dBm(ue.SERV_SITE_IDX) + Offset_A3 < ue.RSRP_dBm(handover.targ_idx);
    end

    % Handover decision algorithm
    if ~handover.preparation_state && ~handover.execution_state
        if any(cond1_enter)
            % 조건이 처음으로 만족되면 TTT 체크 변수 생성
            if handover.TTT_check == 0
                ue.handover.TTT_check = current_time; % 수정: ue.handover로 접근
            end
            % Find the RSRP_dBm index with the highest value satisfying the condition
            valid_indices = find(cond1_enter);
            [~, max_idx] = max(ue.RSRP_dBm(valid_indices));
            new_site_idx = valid_indices(max_idx);

            if new_site_idx ~= ue.SERV_SITE_IDX
                % Check if the conditions are satisfied for TTT
                if current_time - ue.handover.TTT_check >= TTT + prep_delay % 수정: ue.handover로 접근
                % if current_time - ue.handover.TTT_check >= TTT
                    ue.handover = handover.initiate_preparation(current_time, new_site_idx);
                end
            end
        else
            % 조건이 만족되지 않으면 TTT 체크 변수 초기화 및 RLF 증가
            ue.handover.TTT_check = 0; % 수정: ue.handover로 접근
            %ue.RLF = ue.RLF + 1;
        end

    elseif handover.preparation_state && ~handover.execution_state
        if cond2_t_enter
            if handover.exec_TTT_check == 0
                ue.handover.exec_TTT_check = current_time; % 수정: ue.handover로 접근
            end
            if current_time - ue.handover.exec_TTT_check >= TTT
            % if current_time - ue.handover.exec_TTT_check >= TTT + exec_delay % 수정: ue.handover로 접근
                ue.handover = handover.initiate_execution(current_time);
                ue.SERV_SITE_IDX = handover.targ_idx;  % Perform the handover
                ue.HO = ue.HO + 1;
                ue.handover = handover.reset(handover.targ_idx);  % Reset the handover state
            end
        else
            % 조건이 만족되지 않으면 exec_TTT_check 변수 초기화 및 RLF 증가
            ue.handover.exec_TTT_check = 0; % 수정: ue.handover로 접근
            ue.handover = handover.reset(handover.targ_idx);  % Reset the handover state
            %ue = ue.update_serv_site_idx(sat.BORE_X, sat.BORE_Y);
            %ue.RLF = ue.RLF + 1;  % RLF 증가
        end
    end
end
