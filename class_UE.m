% =================================================================
% Winner LAB, Ajou University
% Distance-based HO Parameter Optimization Protocol Code
% Prototype    : class_UE.m
% Type         : MATLAB Class
% Author       : Jongtae Lee
% Revision     : v1.0   2024.06.04
% Modified     : 2024.07.24
% =================================================================

classdef class_UE
    properties
        LOC_X;
        LOC_Y;
        initial_LOC_X;
        initial_LOC_Y;
        ALTITUDE;
        NOISE_dBm;
        NOISE_mwatt;
        SERV_SITE_IDX;
        % SERV_SITE_IDX_LIST = zeros(1, 127);
        INTF_TOTAL_mwatt;
        INTF_TOTAL_dB;

        % Handovers
        handover;               % Handover class instance
        HO;                     % Handover count
        HOPP;
        RBs;
        rlf_instance;
        rlf_indicator;           % RLF class instance
        rlf_timer;
        RLF;                    % Radio Link Failure count
        last_ho_time;
        last_site_idx;
        DELAY;
        PACKET_LOSS;
        current_serving_time = 0; % 현재 serving site에 머문 시간
        current_serving_start_time = 0; % 현재 site로 바뀐 시점

        % HOPP 관련 추가 변수
        hopp_instance;          % HOPP class instance
        pre_ho_site_idx;        % HO 이전의 SERV_SITE_IDX
        pre_ho_time;            % HO 이전의 시간
        post_ho_site_idx;       % HO 이후의 SERV_SITE_IDX
        post_ho_time;           % HO 이후의 시간

        % 127 beams data
        ENV_DIS = zeros(1, 127);
        ENV_ANG = zeros(1, 127);
        ENV_ELEV = zeros(1, 127);
        ML = zeros(1, 127);
        Xp = zeros(1, 127);     % Xp 값 추가

        % 127 signal data
        LOSS = zeros(1, 127);
        AGGAIN = zeros(1, 127);
        SIG_pw_dBm = zeros(1, 127);
        SIG_pw_mwatt = zeros(1, 127);
        SINR = zeros(1, 127);
        % SINR_HIST = zeros(3, 127); % K-filter 3 SINR
        % SINR_AVG = zeros(1, 127); % K-filter average

        SNR = zeros(1, 127);
        SIR = zeros(1, 127);
        RSRP_dBm = zeros(1, 127);
        RSRP_mW = zeros(1, 127);
        RSRP_FILTERED = zeros(1, 127); % 필터링된 RSRP 값
        filter_coeff_a; % 필터 계수 a

        % Handheld parameter
        RX_GAIN = 0;              % dBi [RX antenna gain]
        NF = 7;                   % dB [Noise figure]
        TEMP = 290;               % K [Handheld antenna Temperature]
    end

    methods
        % UE 객체 생성
        function obj = class_UE(loc_x, loc_y, altitude)
            % Constructor: initialize LOC_X, LOC_Y, ALTITUDE with given values
            obj.LOC_X = loc_x;
            obj.LOC_Y = loc_y;
            obj.initial_LOC_X = loc_x; % 초기 위치 저장
            obj.initial_LOC_Y = loc_y; % 초기 위치 저장
            obj.ALTITUDE = altitude;

            % IMPORT '작업공간'
            BW = 20e6;                      % 20 MHz [Bandwidth]

            % % Thermal Noise [mW] 계산
            % obj.NOISE_dBm = -174 + 10*log10(BW) + obj.NF;
            % obj.NOISE_mwatt = 10^(obj.NOISE_dBm / 10);

            % RB 대역폭 [Hz]
            RB_BW = 180e3;  % 180 kHz
            
            % Thermal Noise [mW] 계산
            obj.NOISE_dBm = -174 + 10*log10(RB_BW) + obj.NF;  % RB 대역폭을 사용
            obj.NOISE_mwatt = 10^(obj.NOISE_dBm / 10);

            
            % INIT_SET
            obj.INTF_TOTAL_mwatt = 0;
            obj.INTF_TOTAL_dB = 0;
            obj.handover = class_Handover(0);
            obj.HO = 0;
            obj.RBs = 0;
            obj.HOPP = 0; % Initialize handover ping-pong count
            obj.RLF = 0;
            obj.rlf_instance = [];
            obj.rlf_indicator = 0;
            obj.rlf_timer = 0;
            obj.last_ho_time = -Inf;
            obj.last_site_idx = 0;
            obj.DELAY = 0;
            obj.PACKET_LOSS = 0;

            % HOPP 초기화
            obj.hopp_instance = [];
            obj.pre_ho_site_idx = 0;
            obj.pre_ho_time = 0;
            obj.post_ho_site_idx = 0;
            obj.post_ho_time = 0;
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
                ue_array(i).rlf_timer = 0;
                ue_array(i).hopp_instance = []; % HOPP 초기화
                ue_array(i).DELAY = 0;
                ue_array(i).PACKET_LOSS = 0;
            end
        end

        % SERV_SITE_IDX 업데이트 메서드
        % function obj = update_serv_site_idx(obj, BORE_X, BORE_Y)
        function obj = update_serv_site_idx(obj, BORE_X, BORE_Y)
            distances = sqrt((BORE_X - obj.LOC_X).^2 + (BORE_Y - obj.LOC_Y).^2);
            [~, min_idx] = min(distances);
            % % disp(['Current Site Index: ', num2str(obj.SERV_SITE_IDX)]);
            % % disp(['New Site Index: ', num2str(min_idx)]);
            obj.SERV_SITE_IDX = min_idx;

            % if isempty(obj.SERV_SITE_IDX) || obj.SERV_SITE_IDX ~= min_idx
            %     obj.SERV_SITE_IDX = min_idx;
            %     obj.current_serving_start_time = current_time;
            %     obj.current_serving_time = 0;
            % else
            %     % 같은 서빙 셀 유지 중: 체류시간 증가 구현
            %     obj.current_serving_time = current_time - obj.current_serving_start_time;
            % end

        end


        % ENV_DIS, ENV_ANG, ENV_ELEV 배열을 업데이트하는 메서드
        function obj = update_env(obj, dis_array, ang_array, elev_array)
            if length(dis_array) == 127 && length(ang_array) == 127 && length(elev_array) == 127
                obj.ENV_DIS = dis_array;
                obj.ENV_ANG = ang_array;
                obj.ENV_ELEV = elev_array;
            else
                error('Input arrays must be of length 127');
            end
        end

        % LOSS 배열을 업데이트하는 메서드
        function obj = update_loss(obj)
            % LOSS 계산
            FREQ = 2e9;                     % 2GHz [Frequency band]
            loss_array = GET_LOSS(FREQ, obj.ENV_DIS, obj.ENV_ELEV);
            % loss_array = GET_LOSS_riv(FREQ, obj.ENV_DIS, obj.ENV_ELEV);
            if length(loss_array) == 127
                obj.LOSS = loss_array;
            else
                error('Loss array must be of length 127');
            end
        end

        % AGGAIN 배열을 업데이트하는 메서드
        function obj = update_aggain(obj, maxgain)
            FREQ = 2e9;                     % 2GHz [Frequency band]
            aggain_array = GET_AGGAIN(obj.ENV_ANG, maxgain, FREQ, 2); % (SAT Aperture is 2)
            if length(aggain_array) == 127
                obj.AGGAIN = aggain_array;
            else
                error('Aggain array must be of length 127');
            end
        end

        % ML 값을 업데이트하는 메서드
        function obj = update_ml(obj, BORE_X, BORE_Y)
            obj.ML = GET_DIS_ML(BORE_X, BORE_Y, obj.LOC_X, obj.LOC_Y);
        end

        function obj = update_xp(obj, BORE_X)
            % 동일한 Xp 값을 가져야 하는 셀 그룹 정의 (group 1, 2, 3만 사용)
            group1 = [98, 67, 42, 23, 10, 3, 1, 6, 16, 32, 54, 82, 116];
            group2 = [97, 66, 41, 22, 9, 2, 7, 17, 33, 55, 83, 117];
            group3 = [96, 65, 40, 21, 8, 19, 18, 34, 56, 84, 118];
        
            % 각 그룹에 대해 첫 번째 셀을 기준으로 Xp 값 미리 계산
            xp_group1 = abs(BORE_X(group1(1)) - obj.LOC_X);
            xp_group2 = abs(BORE_X(group2(1)) - obj.LOC_X);
            xp_group3 = abs(BORE_X(group3(1)) - obj.LOC_X);
            
            % 각 BORE_X 값에 대해 적절한 Xp 값을 할당
            for i = 1:numel(BORE_X)
                if ismember(i, group1)
                    obj.Xp(i) = xp_group1;  % 그룹 1에 속하는 셀들에 동일한 Xp 할당
                elseif ismember(i, group2)
                    obj.Xp(i) = xp_group2;  % 그룹 2에 속하는 셀들에 동일한 Xp 할당
                elseif ismember(i, group3)
                    obj.Xp(i) = xp_group3;  % 그룹 3에 속하는 셀들에 동일한 Xp 할당
                else
                    % 그룹에 속하지 않은 셀은 기존 방식으로 Xp 계산
                    obj.Xp(i) = abs(BORE_X(i) - obj.LOC_X);
                end
            end
        end

        % % RSRP 값을 업데이트하는 메서드
        % function obj = update_rsrp(obj, sat_txpw_dbm)
        %     % RSRP 계산
        %     ENV_RSRP_dBm = sat_txpw_dbm + obj.AGGAIN - obj.LOSS;
        %     obj.RSRP_dBm = ENV_RSRP_dBm;
        %     obj.RSRP_mW = 10.^(ENV_RSRP_dBm / 10);
        % end
        
        % 원재형 OPNET 버전으로 RSRP 계산
        function obj = update_rsrp(obj, sat_txpw_dbm)
            % 전체 송신 전력에서 하나의 RB로 나눔 (20MHz = 100 RB 기준)
            sat_txpw_per_RB_dbm = sat_txpw_dbm - 10*log10(100);

            % RSRP 계산 (6개의 Reference Signal 사용)
            ENV_RSRP_dBm = sat_txpw_per_RB_dbm + obj.AGGAIN - obj.LOSS - 10*log10(6);

            % RSRP 값을 dBm과 mW로 저장
            obj.RSRP_dBm = ENV_RSRP_dBm;
            obj.RSRP_mW = 10.^(ENV_RSRP_dBm / 10);
        end
        
        %--- 신규 추가 25.03.13
        % 필터 계수 계산
        function obj = set_filter_coeff(obj, k_rsrp)
            obj.filter_coeff_a = 1 / (2^(k_rsrp / 4));
        end

        % RSRP 필터링 적용
        function obj = update_rsrp_filtered(obj)
            if all(obj.RSRP_FILTERED == 0)
                % 최초 측정값은 필터링 없이 사용
                obj.RSRP_FILTERED = obj.RSRP_dBm;
            else
                % Layer 3 Filtering 적용 (이전 값과 현재 값만을 고려하고 있음)
                obj.RSRP_FILTERED = (1 - obj.filter_coeff_a) * obj.RSRP_FILTERED + obj.filter_coeff_a * obj.RSRP_dBm;
            end
        end
        %===
        
        % INTF_TOTAL 및 SINR을 모든 셀에 대해 계산하는 메서드
        function obj = update_intf_total_all_cells(obj)
            num_cells = length(obj.RSRP_mW); % 전체 셀의 개수
            obj.INTF_TOTAL_mwatt = zeros(1, num_cells); % 각 셀의 간섭값 저장 배열
            obj.SINR = zeros(1, num_cells); % 각 셀의 SINR 저장 배열
        
            for i = 1:num_cells
                % 현재 기준 셀(i)의 RSRP 값을 제외한 모든 셀의 RSRP 합산 (간섭 계산)
                interference_mW = sum(obj.RSRP_mW) - obj.RSRP_mW(i);
        
                % 현재 기준 셀(i)의 간섭 값 저장
                obj.INTF_TOTAL_mwatt(i) = interference_mW;
        
                % SINR 계산: 현재 셀의 신호 대 간섭+잡음 비율
                obj.SINR(i) = 10 * log10(obj.RSRP_mW(i) / (interference_mW + obj.NOISE_mwatt));
            end
        end
        
        % SINR에 대해 K-filter를 적용하기 위한 메서드
        function obj = update_sinr_history(obj)
            obj.SINR_HIST = [obj.SINR; obj.SINR_HIST(1:end-1, :)]; % FIFO
            obj.SINR_AVG = mean(obj.SINR_HIST, 1); % Average Calculation
        end

        % % INTF_TOTAL 값을 업데이트하는 메서드 (근처 61개의 셀만 고려)
        % function obj = update_intf_total(obj)
        %     % 127개의 RSRP 값 중 근처 61개 셀 선택
        %     distances = obj.ENV_DIS;
        %     [~, idxs] = mink(distances, 61);
        %     selected_RSRP_mW = obj.RSRP_mW(idxs);
        % 
        %     % INTF_TOTAL 계산
        %     total_rsrp_mW = sum(selected_RSRP_mW);
        %     own_rsrp_mW = obj.RSRP_mW(obj.SERV_SITE_IDX);
        %     obj.INTF_TOTAL_mwatt = total_rsrp_mW - own_rsrp_mW;
        %     obj.INTF_TOTAL_dB = 10 * log10(obj.INTF_TOTAL_mwatt);
        % end
        % 
        % % SIR 및 SINR 값을 업데이트하는 메서드
        % function obj = update_sir_sinr(obj)
        %     % SIR 및 SINR 계산
        %     own_rsrp_mW = obj.RSRP_mW(obj.SERV_SITE_IDX);
        %     obj.SNR = 10 * log10(own_rsrp_mW / obj.NOISE_mwatt);
        %     obj.SIR = 10 * log10(own_rsrp_mW / obj.INTF_TOTAL_mwatt);
        %     obj.SINR = 10 * log10(own_rsrp_mW / (obj.INTF_TOTAL_mwatt + obj.NOISE_mwatt));
        % end

        % 무작위 이동 메서드
        function obj = move_randomly(obj, distance)
            angle = rand() * 2 * pi; % 0 to 360 degrees in radians
            obj.LOC_X = obj.LOC_X + distance * cos(angle);
            obj.LOC_Y = obj.LOC_Y + distance * sin(angle);
        end

        function obj = check_RLF(obj, sat, current_time, T310)
            Q_in = -8; % RLF 조건 SINR 값
            Q_out = -6; % RLF 조건 해제 SINR 값
        
            % 처음 Q_in에 진입한 순간
            if isempty(obj.rlf_instance) && obj.SINR(obj.SERV_SITE_IDX) < Q_in
                obj.rlf_instance = class_RLF(current_time);
            % 이미 RLF 측정 중인 경우
            elseif ~isempty(obj.rlf_instance)
                if obj.SINR(obj.SERV_SITE_IDX) >= Q_out
                    obj.rlf_instance = [];
                else
                    obj.rlf_instance = obj.rlf_instance.update_T310(current_time);
                    if obj.rlf_instance.T310_check >= T310
                        obj.RLF = obj.RLF + 1;
                        obj.rlf_instance = [];
                        
                        % 업데이트된 객체를 다시 할당
                        obj = obj.update_serv_site_idx(sat.BORE_X, sat.BORE_Y, current_time);
                    end
                end
            end
        end

        function obj = calculate_ToS(obj, sample_time)
            site_durations = diff([0; find(diff(obj.SERV_SITE_IDX) ~= 0); length(obj.SERV_SITE_IDX)]);
            site_indices = obj.SERV_SITE_IDX(site_durations(1:end-1) + 1);
            for i = 1:length(site_durations) - 1
                site_idx = site_indices(i);
                duration = site_durations(i) * sample_time;
                if isKey(obj.ToS, site_idx)
                    obj.ToS(site_idx) = obj.ToS(site_idx) + duration;
                else
                    obj.ToS(site_idx) = duration;
                end
            end
        end

    end
end