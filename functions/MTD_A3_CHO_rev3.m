% =================================================================
% Winner LAB, Ajou University
% Distance-based HO Parameter Optimization Protocol Code
% Prototype    : MTD_A3_CHO_rev5.m
% Type         : MATLAB function Code
% Author       : Jongtae Lee
% Revision     : v1.0   2024.06.04
% Modified     : 2024.08.30
% =================================================================

%% A3-based CHO in EMC (Preparation state triggered only when condition is met)
function ue = MTD_A3_CHO_rev3(ue, sat, Offset_A3, TTT, current_time)
    %handover = ue.handover;
    PD = (600000 / 3e8);  % 빛의 속도에 따른 전파 지연 시간
    
    % 현재 서빙 셀의 RSRP 값
    current_rsrp = ue.RSRP_dBm(ue.SERV_SITE_IDX);

    % Step 1: Preparation state
    if ~ue.handover.preparation_state && ~ue.handover.execution_state
        % 서빙 셀보다 RSRP가 큰 셀이 하나라도 있으면 상위 6개의 타겟 셀 찾기
        if any(ue.RSRP_dBm(ue.SERV_SITE_IDX) < ue.RSRP_dBm)
            % 서빙 셀 제외한 다른 셀들 중 RSRP가 높은 상위 6개의 셀을 찾음
            other_rsrp = ue.RSRP_dBm;
            other_rsrp(ue.SERV_SITE_IDX) = -Inf;  % 서빙 셀의 RSRP를 제외

            % 상위 6개의 타겟 셀 인덱스를 저장
            [~, sorted_idx] = sort(other_rsrp, 'descend');
            top6_idx = sorted_idx(1:min(6, length(sorted_idx)));  % 상위 6개의 셀 인덱스 저장 (셀 수가 6개 미만일 때 처리)
            
            % TTT 체크 변수 생성 (여기가 문제로 top6이 저장되지 않음 문제로 보임
            if ue.handover.TTT_check == 0
                ue.handover.TTT_check = current_time;
                ue.handover.top6_idx = top6_idx;  % 상위 6개의 셀 인덱스 저장
            end
            
            % TTT 시간을 만족하면 핸드오버 준비 상태로 전환
            if current_time - ue.handover.TTT_check >= TTT
                % 타겟 셀을 상위 6개 중에서 가장 높은 RSRP를 가진 셀로 설정
                ue.handover = ue.handover.initiate_preparation(current_time);
            end
        else
            % 조건이 만족되지 않으면 TTT 체크 변수 초기화
            ue.handover.TTT_check = 0;
        end

    % Step 2: Execution state
    elseif ue.handover.preparation_state && ~ue.handover.execution_state
        % 저장해둔 상위 6개의 셀 중 가장 높은 RSRP를 가진 셀을 다시 검사
        top6_idx = ue.handover.top6_idx;  % 저장된 6개의 타겟 셀 인덱스 불러옴
        top6_rsrp = ue.RSRP_dBm(top6_idx);  % 해당 셀들의 RSRP 값

        % 그중 가장 높은 RSRP 값을 가진 셀의 인덱스 선택
        [max_rsrp, best_targ_idx] = max(top6_rsrp);
        best_targ_idx = top6_idx(best_targ_idx);  % 실제 타겟 셀 인덱스

        % 선택된 타겟 셀이 여전히 서빙 셀보다 Offset_A3만큼 높은지 확인
        if ue.RSRP_dBm(ue.SERV_SITE_IDX) + Offset_A3 < max_rsrp
            if ue.handover.exec_TTT_check == 0
                ue.handover.exec_TTT_check = current_time;
            end

            % 핸드오버 실행
            if current_time - ue.handover.exec_TTT_check >= 0
                ue.handover = ue.handover.initiate_execution(current_time);
                ue.SERV_SITE_IDX = best_targ_idx;  % Perform the handover
                ue.HO = ue.HO + 1;
                ue.handover = ue.handover.reset(best_targ_idx);  % 핸드오버 상태 리셋
            end
        else
            % 조건이 만족되지 않으면 exec_TTT_check 초기화 및 핸드오버 상태 리셋
            ue.handover.exec_TTT_check = 0;
            % ue.handover = ue.handover.reset(handover.targ_idx);  % 핸드오버 상태 리셋

            % SINR이 임계값 이하인 경우 RLF 처리
            if ue.SINR < -6
                ue.RLF = ue.RLF + 1;
            end
        end
    end
end
