% =================================================================
% Winner LAB, Ajou University
% Distance-based HO Parameter Optimization Protocol Code
% Prototype    : MTD_DD2_HO.m
% Type         : MATLAB function Code
% Author       : Jongtae Lee
% Revision     : v1.0   2024.07.24
% Modified     : 2024.07.24
% =================================================================

function ue = MTD_DD2_HO_rev(ue, Hys, Thresh1, Thresh2, current_time)
    handover = ue.handover;
    TTT = 0;  % 0 ms, 100 ms, 256 ms 등 설정 가능
    PD = (600000 / 3e8);  % 빛의 속도(m/s)를 기준으로 한 1-way 전파 지연 시간(0.02, 2 ms)

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
                ue.handover.TTT_check = current_time;
            end
            
            % 적합한 타겟 셀 설정
            valid_indices = find(ue.ML <= sqrt((43300)^2 + (25000)^2)); % 1단계 필터링

            if any(ismember(valid_indices, find(cond2_enter)))  % 2단계 조건 확인
                new_site_idx = determine_target_idx(valid_indices, ue);  % 타겟 셀 결정

                if new_site_idx ~= ue.SERV_SITE_IDX
                    % Check if the conditions are satisfied for TTT
                    if current_time - ue.handover.TTT_check >= TTT + (2 * PD)
                        ue.handover = handover.initiate_preparation(current_time, new_site_idx);
                    end
                end
            end
        else
            ue.handover.TTT_check = 0; % 조건 불충족 시 TTT 체크 초기화
        end
        
    elseif handover.preparation_state && ~handover.execution_state
        % Execution 단계에서 타겟 셀로 핸드오버 수행 전 조건 확인
        cond1_enter = ue.ML(ue.SERV_SITE_IDX) - Hys > Thresh1;
        cond2_t_enter = ue.ML(handover.targ_idx) + Hys < Thresh2;
        
        if cond1_enter && cond2_t_enter
            if handover.exec_TTT_check == 0
                ue.handover.exec_TTT_check = current_time;
            end
            if current_time - ue.handover.exec_TTT_check >= TTT
                ue.handover = handover.initiate_execution(current_time);
                ue.SERV_SITE_IDX = handover.targ_idx;  % Perform the handover
                ue.handover = handover.reset(handover.targ_idx);  % Reset the handover state
                ue.HO = ue.HO + 1;
            end
        else
            ue.handover.exec_TTT_check = 0; % 조건 불충족 시 exec_TTT 체크 초기화
            ue.handover = handover.reset(handover.targ_idx);  % 핸드오버 상태 초기화
        end
    end
end

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
