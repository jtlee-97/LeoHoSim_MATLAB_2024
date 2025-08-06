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
function ue = MTD_A3_CHO_rev2(ue, Offset_A3, current_time)
    handover = ue.handover;
    % prep_delay = 5 * 0.002;
    % exec_delay = 3 * 0.002;

    % Entering conditions
    cond1_enter = ue.RSRP_dBm(ue.SERV_SITE_IDX) + Offset_A3 < ue.RSRP_dBm;  % 기존 조건 유지
    cond2_t_enter = false;

    if handover.targ_idx > 0
        cond2_t_enter = ue.RSRP_dBm(ue.SERV_SITE_IDX) + Offset_A3 < ue.RSRP_dBm(handover.targ_idx);
    end

    % Handover decision algorithm
    if ~handover.preparation_state && ~handover.execution_state
        % Prep 진입 조건 수정: serv_rsrp가 targ_rsrp보다 -1 높게 측정되는 타겟 셀이 존재하는지 확인
        if any(ue.RSRP_dBm(ue.SERV_SITE_IDX) + Offset_A3 - 1 > ue.RSRP_dBm)
            % 조건이 처음으로 만족되면 TTT 체크 변수 생성
            if handover.TTT_check == 0
                ue.handover.TTT_check = current_time;
            end

            % 신호가 좋은 6개의 셀 저장
            [~, sort_idx] = sort(ue.RSRP_dBm, 'descend');
            valid_indices = sort_idx(1:min(6, length(sort_idx)));

            % prep 활성화
            ue.handover = handover.initiate_preparation(current_time, valid_indices(1)); % 가장 신호 좋은 셀로 우선 설정
        else
            % 조건이 만족되지 않으면 TTT 체크 변수 초기화 및 RLF 증가
            ue.handover.TTT_check = 0;
            %ue.RLF = ue.RLF + 1;
        end

    elseif handover.preparation_state && ~handover.execution_state
        % Exec 진입 조건: prep가 활성화되어 있고, cond1_enter를 만족하는 셀이 있는지 확인
        if any(cond1_enter)
            % cond1_enter를 만족하는 가장 좋은 셀로 변경
            valid_indices = find(cond1_enter);
            [~, max_idx] = max(ue.RSRP_dBm(valid_indices));
            new_site_idx = valid_indices(max_idx);

            % 바로 실행 상태로 진입
            ue.handover = handover.initiate_execution(current_time);
            ue.SERV_SITE_IDX = new_site_idx;  % Perform the handover
            ue.HO = ue.HO + 1;
            ue.handover = handover.reset(new_site_idx);  % Reset the handover state
        else
            % 조건이 만족되지 않으면 exec_TTT_check 변수 초기화 및 RLF 증가
            ue.handover.exec_TTT_check = 0;
            ue.handover = handover.reset(handover.targ_idx);  % Reset the handover state
            if ue.SINR < -6
                ue.RLF = ue.RLF + 1;
            end
        end
    end
end
