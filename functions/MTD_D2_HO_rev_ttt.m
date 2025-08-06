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
% function ue = MTD_D2_HO_rev_ttt(ue, sat, TTT, Hys, Thresh1, Thresh2, current_time)
%     handover = ue.handover;
%     % TTT = 0.1;                    % 0 ms, 100 ms, 256 ms
% 
%     % Entering conditions
%     cond1_enter = ue.ML(ue.SERV_SITE_IDX) - Hys > Thresh1;
%     cond2_enter = ue.ML < Thresh2;
%     % cond2_enter = ue.ML + Hys < Thresh2;
%     cond2_t_enter = false;
% 
%     if handover.targ_idx > 0
%         cond2_t_enter = ue.ML(handover.targ_idx) + Hys < Thresh2;
%     end
% 
%     % Handover decision algorithm
%     if ~handover.preparation_state && ~handover.execution_state
%         if cond1_enter && any(cond2_enter)
%             % 조건이 처음으로 만족되면 TTT 체크 변수 생성
%             if handover.TTT_check == 0
%                 ue.handover.TTT_check = current_time; % 수정: ue.handover로 접근
%             end
% 
%             % Find the MLT index with the shortest distance satisfying the condition
%             % 서빙셀 제외한 가장 가까운 셀을 찾도록 수정
%             valid_indices = find(cond2_enter);
%             valid_indices(valid_indices == ue.SERV_SITE_IDX) = [];  % 서빙셀을 제외
% 
%             % 서빙셀 제외한 유효한 셀 중 가장 가까운 셀 선택
%             if ~isempty(valid_indices)
%                 [~, min_idx] = min(ue.ML(valid_indices));
%                 new_site_idx = valid_indices(min_idx);
%             else
%                 new_site_idx = ue.SERV_SITE_IDX; % 유효한 셀이 없으면 서빙셀 유지
%             end
% 
%             if new_site_idx ~= ue.SERV_SITE_IDX
%                 % Check if the conditions are satisfied for TTT
%                 if current_time - ue.handover.TTT_check >= TTT % 수정: ue.handover로 접근
%                     ue.handover = handover.initiate_preparation(current_time, new_site_idx);
%                 end
%             end
%         else
%             % 조건이 만족되지 않으면 TTT 체크 변수 초기화 및 RLF 증가
%             ue.handover.TTT_check = 0; % 수정: ue.handover로 접근
%             %ue.RLF = ue.RLF + 1;
%         end
% 
%     elseif handover.preparation_state && ~handover.execution_state
%         if cond1_enter && cond2_t_enter
%             if handover.exec_TTT_check == 0
%                 ue.handover.exec_TTT_check = current_time; % 수정: ue.handover로 접근
%             end
%             if current_time - ue.handover.exec_TTT_check >= TTT % 수정: ue.handover로 접근
%                 ue.handover = handover.initiate_execution(current_time);
%                 ue.SERV_SITE_IDX = handover.targ_idx;  % Perform the handover
%                 ue.handover = handover.reset(handover.targ_idx);  % Reset the handover state
%                 ue.HO = ue.HO + 1;
%             end
%         else
%             % 조건이 만족되지 않으면 exec_TTT_check 변수 초기화 및 RLF 증가
%             ue.handover.exec_TTT_check = 0; % 수정: ue.handover로 접근
%             ue.handover = handover.reset(handover.targ_idx);  % Reset the handover state
%             %ue = ue.update_serv_site_idx(sat.BORE_X, sat.BORE_Y);
%             %ue.RLF = ue.RLF + 1;  % RLF 증가
%         end
%     end
% end

function ue = MTD_D2_HO_rev_ttt(ue, sat, Offset, TTT, current_time)
    handover = ue.handover;

    % 단일 조건식: SERV_SITE_IDX에서의 값과 Offset을 이용한 비교
    cond_enter = ue.ML(ue.SERV_SITE_IDX) - Offset > ue.ML;

    % Handover decision algorithm
    if ~handover.preparation_state && ~handover.execution_state
        if any(cond_enter)
            % 조건이 처음으로 만족되면 TTT 체크 변수 생성
            if handover.TTT_check == 0
                ue.handover.TTT_check = current_time;  % TTT 체크 시작
            end
            
            % 서빙셀을 제외한 가장 가까운 셀 선택
            valid_indices = find(cond_enter);
            valid_indices(valid_indices == ue.SERV_SITE_IDX) = [];  % 서빙셀을 제외

            % 서빙셀 제외한 유효한 셀 중 가장 가까운 셀 선택
            if ~isempty(valid_indices)
                [~, min_idx] = min(ue.ML(valid_indices));
                new_site_idx = valid_indices(min_idx);
            else
                new_site_idx = ue.SERV_SITE_IDX;  % 유효한 셀이 없으면 서빙셀 유지
            end

            if new_site_idx ~= ue.SERV_SITE_IDX
                % TTT 시간 이후 핸드오버 준비 시작
                if current_time - ue.handover.TTT_check >= TTT
                    ue.handover = handover.initiate_preparation(current_time, new_site_idx);
                end
            end
        else
            % 조건이 만족되지 않으면 TTT 체크 변수 초기화
            ue.handover.TTT_check = 0;
        end

    elseif handover.preparation_state && ~handover.execution_state
        % 타겟 셀이 여전히 조건을 만족하는지 확인
        if ue.ML(ue.SERV_SITE_IDX) - Offset > ue.ML(handover.targ_idx)
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
            % 조건이 만족되지 않으면 exec_TTT_check 변수 초기화 및 핸드오버 상태 초기화
            ue.handover.exec_TTT_check = 0;
            ue.handover = handover.reset(handover.targ_idx);  % Reset the handover state
        end
    end
end
