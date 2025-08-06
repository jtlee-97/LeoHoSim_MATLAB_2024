% =================================================================
% Winner LAB, Ajou University
% Distance-based HO Parameter Optimization Protocol Code
% Prototype    : MTD_DIS_HO.m
% Type         : MATLAB function Code
% Author       : Jongtae Lee
% Revision     : v1.0   2024.06.04
% Modified     : 2024.06.04
% =================================================================

%% Distance-based HO (D2) in EMC
function ue = MTD_DD2_HO_rev2(ue, Hys, Thresh1, Thresh2, current_time)
    handover = ue.handover;
    TTT = 0;                    % 0 ms, 100 ms, 256 ms
    
    % Entering conditions
    cond1_enter = ue.ML(ue.SERV_SITE_IDX) - Hys > Thresh1;
    cond2_enter = ue.ML + Hys < Thresh2;
    cond2_t_enter = false;
    
    if handover.targ_idx > 0
        cond2_t_enter = ue.ML(handover.targ_idx) + Hys < Thresh2;
    end

    % Handover decision algorithm
    if ~handover.preparation_state && ~handover.execution_state
        if cond1_enter && any(cond2_enter)
            % 조건이 처음으로 만족되면 TTT 체크 변수 생성
            if handover.TTT_check == 0
                ue.handover.TTT_check = current_time; % 수정: ue.handover로 접근
            end
            
            % 적합한 타겟 셀 설정
            valid_indices = find(cond2_enter);
            new_site_idx = determine_target_idx(valid_indices, ue);  % 타겟 셀 결정

            if new_site_idx ~= ue.SERV_SITE_IDX
                % Check if the conditions are satisfied for TTT
                if current_time - ue.handover.TTT_check >= TTT % 수정: ue.handover로 접근
                    ue.handover = handover.initiate_preparation(current_time, new_site_idx);
                end
            end
        else
            % 조건이 만족되지 않으면 TTT 체크 변수 초기화 및 RLF 증가
            ue.handover.TTT_check = 0; % 수정: ue.handover로 접근
            %ue.RLF = ue.RLF + 1;
        end
        
    elseif handover.preparation_state && ~handover.execution_state
        if cond1_enter && cond2_t_enter
            if handover.exec_TTT_check == 0
                ue.handover.exec_TTT_check = current_time; % 수정: ue.handover로 접근
            end
            if current_time - ue.handover.exec_TTT_check >= TTT % 수정: ue.handover로 접근
                ue.handover = handover.initiate_execution(current_time);
                ue.SERV_SITE_IDX = handover.targ_idx;  % Perform the handover
                ue.handover = handover.reset(handover.targ_idx);  % Reset the handover state
                ue.HO = ue.HO + 1;
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

%% Target Cell Selection Function
function new_site_idx = determine_target_idx(valid_indices, ue)
    % Step 3.1: 같은 XP 값을 가지는 셀 필터링
    same_xp_indices = valid_indices(ue.Xp(valid_indices) == ue.Xp(ue.SERV_SITE_IDX));
    
    if ~isempty(same_xp_indices)
        % Step 3.1.1: XP가 작은 셀이 존재하는지 확인
        smaller_xp_indices = same_xp_indices(ue.Xp(same_xp_indices) < ue.Xp(ue.SERV_SITE_IDX));
        if ~isempty(smaller_xp_indices)
            [~, min_idx] = min(ue.ML(smaller_xp_indices));
            new_site_idx = smaller_xp_indices(min_idx);
            return;
        else
            % XP가 같은 셀 중에서 최소 ML을 가지는 셀 선택
            [~, min_idx] = min(ue.ML(same_xp_indices));
            new_site_idx = same_xp_indices(min_idx);
            return;
        end
    else
        % Step 3.2: XP가 작은 셀이 존재하는지 확인
        smaller_xp_indices = valid_indices(ue.Xp(valid_indices) < ue.Xp(ue.SERV_SITE_IDX));
        if ~isempty(smaller_xp_indices)
            [~, min_idx] = min(ue.ML(smaller_xp_indices));
            new_site_idx = smaller_xp_indices(min_idx);
            return;
        else
            % 가장 가까운 셀을 선택
            [~, min_idx] = min(ue.ML(valid_indices));
            new_site_idx = valid_indices(min_idx);
            return;
        end
    end

    % Step 4: 조건 만족 못한 경우 SERV_SITE_IDX 유지 (보호코드)
    new_site_idx = ue.SERV_SITE_IDX;
end
