% =================================================================
% Winner LAB, Ajou University
% Distance-based HO Parameter Optimization Protocol Code
% Prototype    : MTD_A3_BHO.m
% Type         : MATLAB function Code
% Author       : Jongtae Lee
% Revision     : v1.0   2024.08.27
% Modified     : 2024.08.27
% =================================================================

%% Simple A3-based HO with TTT
function ue = MTD_A3_BHO(ue, sat, Offset_A3, TTT, current_time)
    PD = (600000 / 3e8);  % 빛의 속도(m/s)를 기준으로 한 1-way 전파 지연 시간(0.02, 2 ms)
    handover = ue.handover;
    
    % 현재 서빙 셀의 RSRP 값
    current_rsrp = ue.RSRP_dBm(ue.SERV_SITE_IDX);

    % 서빙 셀 제외한 다른 셀들 중 가장 높은 RSRP를 가진 셀의 인덱스와 값 찾기
    other_rsrp = ue.RSRP_dBm;
    other_rsrp(ue.SERV_SITE_IDX) = -Inf;  % 서빙 셀의 값을 무한히 낮게 설정하여 제외
    [max_rsrp, targ_idx] = max(other_rsrp);
    
    % Entering condition: 가장 높은 RSRP를 가진 셀의 RSRP 값이 서빙 셀의 RSRP + Offset_A3를 초과하는지 확인
    if max_rsrp > current_rsrp + Offset_A3
        % 조건이 처음으로 만족되면 TTT 체크 변수 생성
        if handover.TTT_check == 0
            ue.handover.TTT_check = current_time;
        end
        
        % TTT를 만족하도록 일정 시간 유지되면 핸드오버 실행
        if current_time - ue.handover.TTT_check >= TTT
            ue.SERV_SITE_IDX = targ_idx;  % 핸드오버 실행
            ue.HO = ue.HO + 1;  % 핸드오버 카운터 증가
            ue.RBs = ue.RBs + 1; % MR에 대한 RB 추가
            ue.RBs = ue.RBs + 2; % CMD에 대한 RB 추가
            ue.RBs = ue.RBs + 6; % RA에 대한 RB 추가
            ue.RBs = ue.RBs + 1; % CF에 대한 RB 추가
            if ue.SINR < -8
                ue.RLF = ue.RLF + 1;
            end
            ue.handover = handover.reset(targ_idx);  % 핸드오버 상태 리셋
        end
    else
        % 조건이 만족되지 않으면 TTT 체크 변수 초기화
        ue.handover.TTT_check = 0;
    end
end


% BHO는 트리거 시점에서 최고의 셀을 지정해서 CMD로 전달할 것
% CHO는 execution 단계에서 최고의 셀을 지정할 것