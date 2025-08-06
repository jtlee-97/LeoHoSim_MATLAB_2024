% =================================================================
% Winner LAB, Ajou University
% Distance-based HO Parameter Optimization Protocol Code
% Prototype    : MTD_DIS_HO.m
% Type         : MATLAB function Code
% Author       : Jongtae Lee
% Revision     : v1.0   2024.06.04
% Modified     : 2024.06.04
% =================================================================

%% Distance-based HO (Distance-A3) in EMC
function ue = MTD_D2_HO(ue, sat, Offset, current_time)
    handover = ue.handover;
    TTT = 0;  % 0 ms, 100 ms, 256 ms

    % Entering condition
    cond_enter = ue.ML(ue.SERV_SITE_IDX) - Offset > ue.ML;  % 단일 조건문 사용

    % Handover decision algorithm
    if ~handover.preparation_state && ~handover.execution_state
        if any(cond_enter)
            ue.RBs = ue.RBs + 1; % MR에 대한 RB 추가
            % 조건이 처음으로 만족되면 TTT 체크 변수 생성
            if handover.TTT_check == 0
                ue.handover.TTT_check = current_time;
            end
            
            % Find the MLT index with the shortest distance satisfying the condition
            valid_indices = find(cond_enter);
            [~, min_idx] = min(ue.ML(valid_indices));
            new_site_idx = valid_indices(min_idx);

            if new_site_idx ~= ue.SERV_SITE_IDX
                % Check if the conditions are satisfied for TTT
                if current_time - ue.handover.TTT_check >= TTT
                    ue.handover = handover.initiate_preparation(current_time, new_site_idx);
                    ue.RBs = ue.RBs + 2; % CMD에 대한 RB 추가
                    if ue.SINR < -8
                        ue.RLF = ue.RLF + 1;
                    end
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
                % ue.RBs = ue.RBs + 2; % CMD에 대한 RB 추가
                ue.RBs = ue.RBs + 6; % RA에 대한 RB 추가
                ue.RBs = ue.RBs + 1; % CF에 대한 RB 추가
            end
        end
        % else
        %     % 조건이 만족되지 않으면 exec_TTT_check 변수 초기화 및 RLF 증가
        %     ue.handover.exec_TTT_check = 0;
        %     ue.handover = handover.reset(handover.targ_idx);
        % end
    end
end



% function ue = MTD_D2_HO(ue, sat, Hys, Thresh1, Thresh2, current_time)
%     handover = ue.handover;
%     TTT = 0;                    % 0 ms, 100 ms, 256 ms
% 
%     % Entering conditions
%     cond1_enter = ue.ML(ue.SERV_SITE_IDX) - Hys > Thresh1;
%     cond2_enter = ue.ML + Hys < Thresh2;
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
%             % Find the MLT index with the shortest distance satisfying the condition
%             valid_indices = find(cond2_enter);
%             [~, min_idx] = min(ue.ML(valid_indices));
%             new_site_idx = valid_indices(min_idx);
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

% function ue = MTD_D2_HO(ue, sat, Offset, current_time)
%     handover = ue.handover;
%     TTT = 0;  % 0 ms, 100 ms, 256 ms
% 
%     % Entering condition (유일한 조건식)
%     cond_enter = ue.ML(ue.SERV_SITE_IDX) - Offset > ue.ML;
% 
%     % Handover decision algorithm
%     if ~handover.preparation_state && ~handover.execution_state
%         if any(cond_enter)
%             % Valid indices 저장
%             valid_indices = find(cond_enter);
%             valid_indices(valid_indices == ue.SERV_SITE_IDX) = [];  % 서빙셀 제외
%             ue.handover = handover.update_valid_indices(valid_indices);  % valid_indices 저장
% 
%             % TTT 체크 변수 생성
%             if handover.TTT_check == 0
%                 ue.handover.TTT_check = current_time;  % TTT 체크 시작
%             end
%         else
%             % 조건이 만족되지 않으면 TTT 체크 변수 초기화
%             ue.handover.TTT_check = 0;
%         end
% 
%     elseif handover.preparation_state && ~handover.execution_state
%         % 저장된 valid_indices를 불러오기
%         valid_indices = handover.valid_indices;
% 
%         % 조건이 만족하는지 다시 확인
%         cond_enter = ue.ML(valid_indices) < ue.ML(ue.SERV_SITE_IDX) - Offset;
%         valid_indices = valid_indices(cond_enter);  % 조건 만족하지 않는 셀 제외
% 
%         if ~isempty(valid_indices)
%             % 가장 가까운 셀을 선택 (ML이 가장 작은 셀)
%             [~, min_idx] = min(ue.ML(valid_indices));
%             new_site_idx = valid_indices(min_idx);
% 
%             if new_site_idx ~= ue.SERV_SITE_IDX
%                 % TTT 조건이 만족되면 핸드오버 준비 수행
%                 if current_time - ue.handover.TTT_check >= TTT
%                     ue.handover = handover.initiate_preparation(current_time, new_site_idx);
%                 end
%             end
%         else
%             % 조건이 만족되지 않으면 TTT 체크 초기화
%             ue.handover.TTT_check = 0;
%             ue.handover = handover.reset_valid_indices();  % 유효한 후보 셀 초기화
%         end
%     end
% end
