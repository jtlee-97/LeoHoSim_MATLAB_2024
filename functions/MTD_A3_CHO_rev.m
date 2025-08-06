% % =================================================================
% % Winner LAB, Ajou University
% % Distance-based HO Parameter Optimization Protocol Code
% % Prototype    : MTD_A3_CHO.m
% % Type         : MATLAB function Code
% % Author       : Jongtae Lee
% % Revision     : v1.0   2024.06.04
% % Modified     : 2024.06.04
% % =================================================================

%% A3-based HO in EMC (SINR, RSRP)
function ue = MTD_A3_CHO_rev(ue, Offset_A3, TTT, current_time)
    handover = ue.handover;
    % prep_delay = 5 * 0.002;
    % exec_delay = 3 * 0.002;
    PD = (600000 / 3e8);  % 빛의 속도(m/s)를 기준으로 한 1-way 전파 지연 시간(0.02, 2 ms)

    % Entering conditions (RSRP_FILTERD 버전)
    cond1_enter = ue.RSRP_FILTERED(ue.SERV_SITE_IDX) + Offset_A3 < ue.RSRP_FILTERED;
    cond2_t_enter = false;

    if handover.targ_idx > 0
        cond2_t_enter = ue.RSRP_FILTERED(ue.SERV_SITE_IDX) + Offset_A3 < ue.RSRP_FILTERED(handover.targ_idx);
    end
    
    % % Entering conditions (SINR 버전)
    % % cond1_enter = ue.SINR(ue.SERV_SITE_IDX) < ue.SINR; % K-filter 사용 X
    % cond1_enter = ue.SINR_AVG(ue.SERV_SITE_IDX) < ue.SINR_AVG; % K-filter 사용 시 
    % 
    % cond2_t_enter = false;
    % 
    % if handover.targ_idx > 0
    %     cond2_t_enter = ue.SINR(ue.SERV_SITE_IDX) + Offset_A3 < ue.SINR(handover.targ_idx);
    % end

    % Handover decision algorithm
    if ~handover.preparation_state && ~handover.execution_state
        %if any(ue.SINR(ue.SERV_SITE_IDX) < ue.SINR)
        if any(ue.RSRP_FILTERED(ue.SERV_SITE_IDX) < ue.RSRP_FILTERED)
            ue.RBs = ue.RBs + 1; % MR에 대한 RB 추가
            % 조건이 처음으로 만족되면 TTT 체크 변수 생성
            if handover.TTT_check == 0
                ue.handover.TTT_check = current_time; % 수정: ue.handover로 접근
            end
            % Find the RSRP_dBm index with the highest value satisfying the condition
            % valid_indices = find(ue.SINR(ue.SERV_SITE_IDX) < ue.SINR);
            valid_indices = find(ue.RSRP_FILTERED(ue.SERV_SITE_IDX) < ue.RSRP_FILTERED);
            %[~, max_idx] = max(ue.SINR(valid_indices));
            [~, max_idx] = max(ue.RSRP_FILTERED(valid_indices));
            new_site_idx = valid_indices(max_idx);

            if new_site_idx ~= ue.SERV_SITE_IDX
                % Check if the conditions are satisfied for TTT
                if current_time - ue.handover.TTT_check >= TTT
                    ue.handover = handover.initiate_preparation(current_time, new_site_idx);
                    ue.RBs = ue.RBs + 2; % CMD에 대한 RB 추가
                    if ue.SINR(ue.SERV_SITE_IDX) < -8
                        ue.RLF = ue.RLF + 1;
                    end
                end
            end
        else
            % 조건이 만족되지 않으면 TTT 체크 변수 초기화 및 RLF 증가
            ue.handover.TTT_check = 0; % 수정: ue.handover로 접근
        end

    elseif handover.preparation_state && ~handover.execution_state
        if cond2_t_enter
            if handover.exec_TTT_check == 0
                ue.handover.exec_TTT_check = current_time; % 수정: ue.handover로 접근
            end
            if current_time - ue.handover.exec_TTT_check >= 0
                ue.handover = handover.initiate_execution(current_time);
                ue.SERV_SITE_IDX = handover.targ_idx;  % Perform the handover
                ue.current_serving_start_time = current_time;
                ue.current_serving_time = 0;
                ue.HO = ue.HO + 1;
                % ue.RBs = ue.RBs + 2; % CMD에 대한 RB 추가
                ue.RBs = ue.RBs + 6; % RA에 대한 RB 추가
                ue.RBs = ue.RBs + 1; % CF에 대한 RB 추가
                ue.handover = handover.reset(handover.targ_idx);  % Reset the handover state
            end
        else
            % 조건이 만족되지 않으면 exec_TTT_check 변수 초기화 및 RLF 증가
            ue.handover.exec_TTT_check = 0; % 수정: ue.handover로 접근
            ue.handover = handover.reset(handover.targ_idx);  % Reset the handover state
            % if ue.SINR(ue.SERV_SITE_IDX) < -6
            %     ue.RLF = ue.RLF + 1;
            % end
        end
    end
end