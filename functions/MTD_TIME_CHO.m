function ue = MTD_TIME_CHO(ue, Offset_A3, TTT, current_time, time_threshold)
    handover = ue.handover;

    % 먼저 체류시간 조건 확인
    if ue.current_serving_time < time_threshold
        return;  % 아직 HO 평가 시작 조건이 안됨
    end

    % 기존 A3 조건 계산
    cond1_enter = ue.RSRP_FILTERED(ue.SERV_SITE_IDX) + Offset_A3 < ue.RSRP_FILTERED;
    cond2_t_enter = false;

    if handover.targ_idx > 0
        cond2_t_enter = ue.RSRP_FILTERED(ue.SERV_SITE_IDX) + Offset_A3 < ue.RSRP_FILTERED(handover.targ_idx);
    end

    % Handover decision algorithm
    if ~handover.preparation_state && ~handover.execution_state
        if any(cond1_enter)
            ue.RBs = ue.RBs + 1;
            if handover.TTT_check == 0
                ue.handover.TTT_check = current_time;
            end

            valid_indices = find(cond1_enter);
            [~, max_idx] = max(ue.RSRP_FILTERED(valid_indices));
            new_site_idx = valid_indices(max_idx);

            if new_site_idx ~= ue.SERV_SITE_IDX
                if current_time - ue.handover.TTT_check >= TTT
                    ue.handover = handover.initiate_preparation(current_time, new_site_idx);
                    ue.RBs = ue.RBs + 2;
                    if ue.SINR(ue.SERV_SITE_IDX) < -8
                        ue.RLF = ue.RLF + 1;
                    end
                end
            end
        else
            ue.handover.TTT_check = 0;
        end

    elseif handover.preparation_state && ~handover.execution_state
        if cond2_t_enter
            if handover.exec_TTT_check == 0
                ue.handover.exec_TTT_check = current_time;
            end
            if current_time - ue.handover.exec_TTT_check >= 0
                ue.handover = handover.initiate_execution(current_time);
                ue.SERV_SITE_IDX = handover.targ_idx;
                ue.current_serving_start_time = current_time;
                ue.current_serving_time = 0;
                ue.HO = ue.HO + 1;
                ue.RBs = ue.RBs + 6 + 1;
                ue.handover = handover.reset(handover.targ_idx);
            end
        else
            ue.handover.exec_TTT_check = 0;
            ue.handover = handover.reset(handover.targ_idx);
        end
    end
end
