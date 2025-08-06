% =================================================================
% Winner LAB, Ajou University
% Distance-based HO Parameter Optimization Protocol Code
% Prototype    : MTD_DD2_HO.m
% Type         : MATLAB function Code
% Author       : Jongtae Lee
% Revision     : v1.0   2024.07.24
% Modified     : 2024.07.24
% =================================================================

function ue = MTD_DD2_HO(ue, sat, Hys, Thresh1, Thresh2, current_time, OPTION)
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
            
            % 조건에 따라 적합한 targ_idx 설정
            valid_indices = find(cond2_enter);
            new_site_idx = determine_target_idx(valid_indices, ue, OPTION);

            if new_site_idx ~= ue.SERV_SITE_IDX
                % Check if the conditions are satisfied for TTT
                if current_time - ue.handover.TTT_check >= TTT + (2 * PD)
                    ue.handover = handover.initiate_preparation(current_time, new_site_idx);
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
            % ue.RLF = ue.RLF + 1;  % RLF 증가
        end
    end
end

function new_site_idx = determine_target_idx(valid_indices, ue, OPTION)
    if OPTION == 1
        % OPTION 1: 가장 가까운 셀을 선택 (D2 방식과 동일)
        [~, min_idx] = min(ue.ML(valid_indices));
        new_site_idx = valid_indices(min_idx);

    elseif OPTION == 2
        % OPTION 2: 서빙 셀 제외, ML 크기 43300 이하의 셀 중에서 서빙 셀과 XP 차이가 더 작은 셀 선택
        % valid_indices = valid_indices(ue.ML(valid_indices) <= 43300);  % ML이 25000 이하인 셀 필터링
        valid_indices = valid_indices(ue.ML(valid_indices) <= sqrt((43300)^2 + (25000)^2));  % ML이 sqrt((43300)^2 + (25000)^2) 이하인 셀 필터링
        if ~isempty(valid_indices)
            % 서빙 셀과의 XP 차이보다 작은 셀을 우선 선택
            current_xp_diff = abs(ue.Xp(ue.SERV_SITE_IDX) - ue.Xp(valid_indices));
            better_indices = valid_indices(current_xp_diff < abs(ue.Xp(ue.SERV_SITE_IDX) - ue.Xp(ue.SERV_SITE_IDX)));

            if ~isempty(better_indices)
                % XP 차이가 더 작은 셀들 중 가장 가까운 셀 선택
                [~, min_idx] = min(ue.ML(better_indices));
                new_site_idx = better_indices(min_idx);
            else
                % XP 차이가 더 작은 셀이 없으면 XP가 같은 셀을 선택
                same_xp_indices = valid_indices(ue.Xp(valid_indices) == ue.Xp(ue.SERV_SITE_IDX));
                if ~isempty(same_xp_indices)
                    [~, min_idx] = min(ue.ML(same_xp_indices));
                    new_site_idx = same_xp_indices(min_idx);
                else
                    % XP가 같은 셀이 없으면 가장 가까운 셀 선택
                    [~, min_idx] = min(ue.ML(valid_indices));
                    new_site_idx = valid_indices(min_idx);
                    % new_site_idx = ue.SERV_SITE_IDX;
                end
            end
        else
            % 조건을 만족하는 셀이 없으면 SERV_SITE_IDX 변경하지 않음
            new_site_idx = ue.SERV_SITE_IDX;
        end
    end
end

% function new_site_idx = determine_target_idx(valid_indices, ue, OPTION)
%     if OPTION == 1
%         % OPTION 1: 가장 가까운 셀을 선택 (D2 방식과 동일)
%         [~, min_idx] = min(ue.ML(valid_indices));
%         new_site_idx = valid_indices(min_idx);
% 
%     elseif OPTION == 2
%         % OPTION 2: 후보셀 필터링 (ML이 sqrt((43300)^2+(25000)^2) 이하인 셀들로 구성)
%         max_ml_value = sqrt((43300)^2 + (25000)^2);
%         filtered_indices = valid_indices(ue.ML(valid_indices) <= max_ml_value);
% 
%         % 서빙셀 제거
%         filtered_indices(filtered_indices == ue.SERV_SITE_IDX) = [];
% 
%         % 필터링된 셀들 출력 (디버그용)
%         disp('Filtered Cells:');
%         for i = 1:length(filtered_indices)
%             fprintf('Cell Index: %d, XP: %d, ML: %d\n', filtered_indices(i), ue.Xp(filtered_indices(i)), ue.ML(filtered_indices(i)));
%         end
% 
%         if ~isempty(filtered_indices)
%             % <1> 필터링 리스트에 동일 XP가 존재하지 않음
%             unique_xp_values = unique(ue.Xp(filtered_indices));
%             if length(unique_xp_values) > 1
%                 % 서빙셀을 제외한 가장 작은 XP를 가지는 셀 && 서빙셀보다 작은 ML을 가지는 셀
%                 [~, min_xp_idx] = min(ue.Xp(filtered_indices));
%                 candidate_idx = filtered_indices(min_xp_idx);
% 
%                 if ue.ML(candidate_idx) < ue.ML(ue.SERV_SITE_IDX)
%                     new_site_idx = candidate_idx;
%                     return;
%                 end
%             end
% 
%             % <2> 필터링 리스트에 동일 XP가 존재함
%             % [1순위 평가] XP가 서빙셀보다 가장 작은 값을 가지는 셀 선택
%             smaller_xp_indices = filtered_indices(ue.Xp(filtered_indices) < ue.Xp(ue.SERV_SITE_IDX));
%             if ~isempty(smaller_xp_indices)
%                 [~, min_xp_idx] = min(ue.ML(smaller_xp_indices));
%                 candidate_idx = smaller_xp_indices(min_xp_idx);
% 
%                 if ue.ML(candidate_idx) < ue.ML(ue.SERV_SITE_IDX)
%                     new_site_idx = candidate_idx;
%                     return;
%                 end
%             end
% 
%             % [2순위 평가] XP가 서빙셀과 동일한 값을 가지는 셀 선택
%             same_xp_indices = filtered_indices(ue.Xp(filtered_indices) == ue.Xp(ue.SERV_SITE_IDX));
%             if ~isempty(same_xp_indices)
%                 [~, min_ml_idx] = min(ue.ML(same_xp_indices));
%                 candidate_idx = same_xp_indices(min_ml_idx);
% 
%                 if ue.ML(candidate_idx) < ue.ML(ue.SERV_SITE_IDX)
%                     new_site_idx = candidate_idx;
%                     return;
%                 end
%             end
%         end
% 
%         % [3순위 평가] 두 조건을 모두 만족하지 않는다면, serv_site_idx 변경하지 않음
%         new_site_idx = ue.SERV_SITE_IDX;
%     end
% end

% function new_site_idx = determine_target_idx(valid_indices, ue, OPTION)
%     if OPTION == 1
%         % OPTION 1: 가장 가까운 셀을 선택 (D2 방식과 동일)
%         [~, min_idx] = min(ue.ML(valid_indices));
%         new_site_idx = valid_indices(min_idx);
% 
%     elseif OPTION == 2
%         % OPTION 2: 후보셀 필터링 (ML이 43300 이하인 셀들로 구성)
%         filtered_indices = valid_indices(ue.ML(valid_indices) <= 43300);
% 
%         % 서빙셀 제거
%         filtered_indices(filtered_indices == ue.SERV_SITE_IDX) = [];
% 
%         if ~isempty(filtered_indices)
%             % [1순위 평가] XP가 가장 작은 셀 선택
%             [~, min_xp_idx] = min(ue.Xp(filtered_indices));
%             candidate_idx = filtered_indices(min_xp_idx);
% 
%             % XP가 가장 작은 셀의 ML이 서빙셀보다 작은지 확인
%             if ue.ML(candidate_idx) < ue.ML(ue.SERV_SITE_IDX)
%                 new_site_idx = candidate_idx;
%                 return;
%             end
% 
%             % [2순위 평가] XP가 서빙셀과 동일한 셀 선택
%             same_xp_indices = filtered_indices(ue.Xp(filtered_indices) == ue.Xp(ue.SERV_SITE_IDX));
%             if ~isempty(same_xp_indices)
%                 [~, min_ml_idx] = min(ue.ML(same_xp_indices));
%                 candidate_idx = same_xp_indices(min_ml_idx);
% 
%                 % XP가 동일한 셀의 ML이 서빙셀보다 작은지 확인
%                 if ue.ML(candidate_idx) < ue.ML(ue.SERV_SITE_IDX)
%                     new_site_idx = candidate_idx;
%                     return;
%                 end
%             end
% 
%             % [3순위 평가] 가장 가까운 XP를 가지는 셀 중에서 서빙셀보다 작은 ML을 가진 셀 선택
%             [~, min_xp_diff_idx] = min(abs(ue.Xp(filtered_indices) - ue.Xp(ue.SERV_SITE_IDX)));
%             candidate_idx = filtered_indices(min_xp_diff_idx);
% 
%             if ue.ML(candidate_idx) < ue.ML(ue.SERV_SITE_IDX)
%                 new_site_idx = candidate_idx;
%                 return;
%             end
%         end
% 
%         % 조건을 만족하는 셀이 없으면 SERV_SITE_IDX 변경하지 않음
%         new_site_idx = ue.SERV_SITE_IDX;
%     end
% end

% function new_site_idx = determine_target_idx(valid_indices, ue, OPTION)
%     if OPTION == 1
%         % OPTION 1: 가장 가까운 셀을 선택 (D2 방식과 동일)
%         [~, min_idx] = min(ue.ML(valid_indices));
%         new_site_idx = valid_indices(min_idx);
% 
%     elseif OPTION == 2
%         % OPTION 2: ML이 43300 이하이고, cond1_enter 및 cond2_enter를 만족하는 셀 필터링
%         % 그리고 후보들 중 서빙셀과 XP 차이가 가장 작은 셀을 선택
% 
%         % 후보 필터링: ML <= 43300인 셀을 필터링
%         filtered_indices = valid_indices(ue.ML(valid_indices) <= 43300);
% 
%         if ~isempty(filtered_indices)
%             % (1번) 서빙셀과 같은 XP를 가지는 셀을 우선 선택
%             same_xp_indices = filtered_indices(ue.Xp(filtered_indices) == ue.Xp(ue.SERV_SITE_IDX));
%             if ~isempty(same_xp_indices)
%                 [~, min_idx] = min(ue.ML(same_xp_indices));
%                 new_site_idx = same_xp_indices(min_idx);
%                 return;
%             end
% 
%             % (2번) 서빙셀보다 더 가까운 XP를 가지는 셀 선택
%             closer_xp_indices = filtered_indices(ue.Xp(filtered_indices) < ue.Xp(ue.SERV_SITE_IDX));
%             if ~isempty(closer_xp_indices)
%                 [~, min_idx] = min(ue.ML(closer_xp_indices));
%                 new_site_idx = closer_xp_indices(min_idx);
%                 return;
%             end
% 
%             % (3번) XP가 동일한 셀이 없고, 더 가까운 XP를 가지는 셀이 없는 경우
%             % 후보 중 가장 가까운 XP를 가지는 셀 선택
%             [~, min_idx] = min(abs(ue.Xp(filtered_indices) - ue.Xp(ue.SERV_SITE_IDX)));
%             new_site_idx = filtered_indices(min_idx);
%         else
%             % 조건을 만족하는 셀이 없으면 SERV_SITE_IDX 변경하지 않음
%             new_site_idx = ue.SERV_SITE_IDX;
%         end
%     end
% end

% function new_site_idx = determine_target_idx(valid_indices, ue, OPTION)
%     if OPTION == 1
%         % OPTION 1: 가장 가까운 셀을 선택 (D2 방식과 동일)
%         [~, min_idx] = min(ue.ML(valid_indices));
%         new_site_idx = valid_indices(min_idx);
% 
%     elseif OPTION == 2
%         % OPTION 2: 서빙 셀 제외, ML 크기 43300 이하의 셀 중에서 서빙 셀과 XP 차이가 더 작은 셀 선택
%         % valid_indices = valid_indices(ue.ML(valid_indices) <= 43300);  % ML이 25000 이하인 셀 필터링
%         valid_indices = valid_indices(ue.ML(valid_indices) <= sqrt((43300)^2 + (25000)^2));  % ML이 sqrt((43300)^2 + (25000)^2) 이하인 셀 필터링
%         if ~isempty(valid_indices)
%             % 서빙 셀과의 XP 차이보다 작은 셀을 우선 선택
%             current_xp_diff = abs(ue.Xp(ue.SERV_SITE_IDX) - ue.Xp(valid_indices));
%             better_indices = valid_indices(current_xp_diff < abs(ue.Xp(ue.SERV_SITE_IDX) - ue.Xp(ue.SERV_SITE_IDX)));
% 
%             if ~isempty(better_indices)
%                 % XP 차이가 더 작은 셀들 중 가장 가까운 셀 선택
%                 [~, min_idx] = min(ue.ML(better_indices));
%                 new_site_idx = better_indices(min_idx);
%             else
%                 % XP 차이가 더 작은 셀이 없으면 XP가 같은 셀을 선택
%                 same_xp_indices = valid_indices(ue.Xp(valid_indices) == ue.Xp(ue.SERV_SITE_IDX));
%                 if ~isempty(same_xp_indices)
%                     [~, min_idx] = min(ue.ML(same_xp_indices));
%                     new_site_idx = same_xp_indices(min_idx);
%                 else
%                     % XP가 같은 셀이 없으면 가장 가까운 셀 선택
%                     [~, min_idx] = min(ue.ML(valid_indices));
%                     new_site_idx = valid_indices(min_idx);
%                     % new_site_idx = ue.SERV_SITE_IDX;
%                 end
%             end
%         else
%             % 조건을 만족하는 셀이 없으면 SERV_SITE_IDX 변경하지 않음
%             new_site_idx = ue.SERV_SITE_IDX;
%         end
%     end
% end
