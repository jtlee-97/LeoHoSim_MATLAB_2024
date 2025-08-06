% =================================================================
% Winner LAB, Ajou University
% Distance-based HO Parameter Optimization Protocol Code
% Prototype    : system_process.m
% Type         : MATLAB code
% Author       : Jongtae Lee
% Revision     : v2.1   2024.06.04
% Modified     : 2024.08.27
% =================================================================

function [histories, episode_results, final_results, master_histories] = system_process(uex, uey, EPISODE, TIMEVECTOR, SITE_MOVE, SAMPLE_TIME, option, Offset, TTT)
    run('system_parameter.m');
    Hys = 0;
    Thresh1_1 = cellISD - cellRadius;
    Thresh1_2 = cellISD/2;
    Thresh1_3 = cellRadius;
    Thresh2 = cellRadius;
    T310 = 1;

    % 객체 생성
    sat = class_SAT();
    ue_array = [class_UE(uex, uey, 0)];
    
    % Data 저장
    histories = repmat(class_History(), numel(ue_array), EPISODE);
    episode_results = repmat(class_EpisodeResult(), numel(ue_array), EPISODE);
    sat_histories = repmat(struct('BORE_X', [], 'BORE_Y', []), 1, EPISODE);
   
    % main Loop
    idx = 1;
    while idx <= EPISODE
        jdx = 1;
        sat = sat.reset_SAT(); % EPISODE 시작할 때마다 SAT 위치 초기화
        ue_array = RESET_UE(ue_array); % EPISODE 시작할 때마다 UE 위치 초기화

        % 초기 prev_BORE_X, prev_BORE_Y 설정
        if jdx == 1
            sat_histories(idx).BORE_X = sat.BORE_X;
            sat_histories(idx).BORE_Y = sat.BORE_Y;
        end
        
        % 첫 번째 히스토리 초기화
        sat_histories(idx).BORE_X = [sat.BORE_X];
        sat_histories(idx).BORE_Y = [sat.BORE_Y];

        % 초기 상태 업데이트
        ue_array = UPDATE_UE(sat, ue_array, true, sat_histories, idx); % true: it is initial state

        while jdx <= length(TIMEVECTOR)
            sat.BORE_Y = sat.BORE_Y + SITE_MOVE;  % Move Next Location (SAT) at 1 TIMEVECTOR
            
            % HO Process 함수 호출 (A3, D2, 제안 D2)
            current_time = jdx * SAMPLE_TIME; % current time in seconds
            
            % SAT 히스토리 업데이트
            sat_histories(idx).BORE_X = [sat_histories(idx).BORE_X; sat.BORE_X];
            sat_histories(idx).BORE_Y = [sat_histories(idx).BORE_Y; sat.BORE_Y];

            % UE 상태 업데이트 (SERV_SITE_IDX 업데이트 포함)
            ue_array = UPDATE_UE(sat, ue_array, false, sat_histories, idx);  % UPDATE UE STATE, false: it is not initial state
            PD = (600000 / 3e8);  % 빛의 속도(m/s)를 기준으로 한 1-way 전파 지연 시간(0.02, 2 ms)

            % 히스토리 업데이트
            for i = 1:numel(ue_array)
                histories(i, idx) = histories(i, idx).update(ue_array(i));
            end

            for i = 1:numel(ue_array)
                ue_array(i) = MTD_TIME_CHO(ue_array(i), Offset, TTT, current_time, 2.0);
                % switch option
                %     % case {1, 2, 3}
                %         % ue_array(i) = MTD_A3_BHO(ue_array(i), sat, Offset, TTT, current_time); % BHO A3 (SINR)
                %     case {1, 2, 3}
                %         ue_array(i) = MTD_A3_CHO_rev(ue_array(i), Offset, TTT, current_time); % CHO A3 (SINR)
                %     % case 7 % 기존 상대비교식 거리CHO
                %         % not consider serving cell state, just consider triggering condition satisfy?
                %         % ue_array(i) = MTD_D2_HO(ue_array(i), sat, Offset, current_time); % Distance
                %     case {4, 5, 6} % 수정한 표준기반 거리CHO
                %         switch option
                %             case 4
                %                 % this option consider serving cell state, if not closer the serving cell? target cell not change
                %                 ue_array(i) = MTD_D2_HO_3gpp(ue_array(i), sat, Hys, (cellISD - cellRadius), cellRadius, current_time); % Distance
                %             case 5
                %                 % this option consider serving cell state, if not closer the serving cell? target cell not change
                %                 ue_array(i) = MTD_D2_HO_3gpp(ue_array(i), sat, Hys, (cellISD/2), cellRadius, current_time); % Distance
                %             case 6
                %                 % this option consider serving cell state, if not closer the serving cell? target cell not change
                %                 ue_array(i) = MTD_D2_HO_3gpp(ue_array(i), sat, Hys, cellRadius, cellRadius, current_time); % Distance
                %         end
                %     case 7
                %         % proposed method
                %         ue_array(i) = MTD_DD2_HO_OID(ue_array(i), sat, Hys, cellISD - cellRadius, Thresh2, current_time); % Distance DD2
                % end
                ue_array(i) = ue_array(i).check_RLF(sat, current_time, T310); % T310을 1로 설정
            end

            for i = 1:numel(ue_array)
                if ue_array(i).last_site_idx ~= ue_array(i).SERV_SITE_IDX
                    ue_array(i).current_serving_start_time = current_time;
                    ue_array(i).last_site_idx = ue_array(i).SERV_SITE_IDX;
                end
                ue_array(i).current_serving_time = current_time - ue_array(i).current_serving_start_time;
            end
            
            % fprintf("t=%.1f, UE=%d, serving_idx=%d, ToS=%.2f sec\n", current_time, i, ue_array(i).SERV_SITE_IDX, ue_array(i).current_serving_time);

            jdx = jdx + 1;
        end

        % if option == 8 && uex == 17000
        %     check = 'point';
        % end

        % 각 에피소드의 평균 값 계산 및 저장
        for i = 1:numel(ue_array)
            episode_results(i, idx) = episode_results(i, idx).calculate_average(histories(i, idx), SAMPLE_TIME);
            if(option == 10)
                check = 'point';
            end
        end
        idx = idx + 1;
    end
    
    % EPISODE 전체에 대한 평균을 저장할 master_histories 초기화
    master_histories = class_History();
    
    % 필드별 평균 계산 (RSRP_dBm과 LOSS만)
    master_histories.RSRP_dBm = mean(cat(3, histories(:,:).RSRP_dBm), 3, 'omitnan');
    master_histories.LOSS = mean(cat(3, histories(:,:).LOSS), 3, 'omitnan');

    % 최종 평균 값 계산
    final_results = repmat(class_FinalResult(), numel(ue_array), 1);
    for i = 1:numel(ue_array)
        final_results(i) = final_results(i).calculate_final_average(episode_results(i, :));
    end
end

function ue_array = RESET_UE(ue_array)
    for i = 1:numel(ue_array)
        ue_array(i).LOC_X = ue_array(i).initial_LOC_X;
        ue_array(i).LOC_Y = ue_array(i).initial_LOC_Y;
        ue_array(i).HO = 0;
        ue_array(i).RBs = 0;
        ue_array(i).HOPP = 0;
        ue_array(i).RLF = 0;
        ue_array(i).rlf_instance = [];
        ue_array(i).rlf_indicator = 0; % RLF 초기화
        ue_array(i).rlf_timer = 0; % RLF 초기화
        ue_array(i).handover = class_Handover(ue_array(i).SERV_SITE_IDX); % Handover 객체 초기화
    end
end

function ue_array = UPDATE_UE(sat, ue_array, is_initial, sat_histories, current_idx)
    run("system_parameter.m");
    num_ues = numel(ue_array);
    for i = 1:num_ues
        % 초기 설정 시 가장 가까운 BORE의 인덱스를 SERV_SITE_IDX로 설정
        if is_initial
            ue_array(i) = ue_array(i).update_serv_site_idx(sat.BORE_X, sat.BORE_Y);
            % ue_array(i).SERV_SITE_IDX = 1;
        end

        % 거리, 각도, 고도각 계산 및 업데이트 (-> UE Class)
        [distances, angles, elevs] = GET_DIS_ANG(sat.BORE_X, sat.BORE_Y, sat.ALTITUDE, ue_array(i).LOC_X, ue_array(i).LOC_Y, ue_array(i).ALTITUDE);
        ue_array(i) = ue_array(i).update_env(distances, angles, elevs);
        % 손실 값 계산 및 업데이트
        ue_array(i) = ue_array(i).update_loss();
        % 안테나 이득 값 계산 및 업데이트
        ue_array(i) = ue_array(i).update_aggain(sat.TX_GAIN);
        % ML 값 계산 및 업데이트
        ue_array(i) = ue_array(i).update_ml(sat.BORE_X, sat.BORE_Y);
        % RSRP 값 계산 및 업데이트
        ue_array(i) = ue_array(i).update_rsrp(sat.TXPW_dBm);
        % INTF_TOTAL 값 계산 및 업데이트
        % ue_array(i) = ue_array(i).update_intf_total();
        % SIR 및 SINR 값 계산 및 업데이트
        % ue_array(i) = ue_array(i).update_sir_sinr();
        ue_array(i) = ue_array(i).update_intf_total_all_cells();
        % Xp 값 계산 및 업데이트
        ue_array(i) = ue_array(i).update_xp(sat.BORE_X);  % Scenario 1

        % ===================== K-filter로 SINR 업데이트 =====================
        % % 기존 SINR 값을 SINR_HIST FIFO 큐에 추가 (최대 k_filter 길이 유지)
        % ue_array(i).SINR_HIST = [ue_array(i).SINR; ue_array(i).SINR_HIST(1:k_filter-1, :)]; 
        % % 각 셀마다 최근 k_filter개의 SINR 평균값을 계산하여 업데이트
        % ue_array(i).SINR_AVG = mean(ue_array(i).SINR_HIST, 1);

        % ===================== K-filter로 RSRP 업데이트 =====================
        % 필터 계수 설정
        ue_array(i) = ue_array(i).set_filter_coeff(k_rsrp);
        % 기존 RSRP 업데이트
        ue_array(i) = ue_array(i).update_rsrp(sat.TXPW_dBm);
        % Layer 3 Filtering 적용
        ue_array(i) = ue_array(i).update_rsrp_filtered();
    end
end
