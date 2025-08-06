classdef class_EpisodeResult
    properties
        SINR = [];
        RSRP = [];
        HO;
        RBs;
        HOPP;  % HOPP 발생 횟수 추가
        RLF;
        ToS = [];  % 각 셀에 머문 시간 저장
        avg_ToS;  % 평균 ToS
        UHO;  % shortToS 방식으로 계산
        avg_Delay; % 새로운 속성 추가
        avg_PACKET_LOSS;
        actual_ToS = []; % 세로 방향으로 저장될 ToS 값
        shortToS = 0; % shortToS 카운트 추가
        SERV_SITE_IDX = []; % serving cell idx 변화시점 검토용
    end

    methods
        function obj = calculate_average(obj, history, sample_time)
            % SINR 값을 저장
            if isempty(obj.SINR)
                obj.SINR = history.SINR;
            else
                obj.SINR = [obj.SINR, history.SINR];
            end
            
            % RSRP 값을 저장 RSRP_dBm_rec
            if isempty(obj.RSRP)
                obj.RSRP = history.RSRP_dBm_rec;
            else
                obj.RSRP = [obj.RSRP, history.RSRP_dBm_rec];
            end
            
            % HO, RLF 값 업데이트
            obj.HO = max(history.HO);
            obj.RBs = max(history.RBs);
            obj.RLF = max(history.RLF);

            % ToS 계산 및 저장 (첫 번째 및 마지막 연속 셀 제외)
            [ToS_durations, avg_ToS_value] = obj.calculate_ToS(history.SERV_SITE_IDX, sample_time);
            obj.ToS = ToS_durations;  % 각 셀에 머문 시간 저장
            obj.avg_ToS = avg_ToS_value;  % 평균 ToS 저장

            % actual_ToS 값을 세로 방향으로 누적하여 저장
            new_actual_ToS = ToS_durations;
            if isempty(obj.actual_ToS)
                obj.actual_ToS = new_actual_ToS;
            else
                obj.actual_ToS = [obj.actual_ToS; new_actual_ToS];  % 세로로 추가
            end

            % shortToS와 UHO, HOPP 계산 (첫 번째 및 마지막 연속 셀 제외)
            obj.shortToS = obj.calculate_shortToS(history.SERV_SITE_IDX);
            obj.UHO = obj.shortToS;  % shortToS와 동일한 방식으로 UHO 계산
            obj.HOPP = obj.calculate_HOPP(history.SERV_SITE_IDX);  % HOPP 계산
        end

        function [ToS_durations, avg_ToS_value] = calculate_ToS(~, serv_site_idx, sample_time)
            % ToS (Time of Stay) 계산 함수: 첫 번째와 마지막 연속 셀 제외하고 각 셀에 머문 시간을 계산
            if length(serv_site_idx) < 3
                ToS_durations = [];  % 데이터가 충분하지 않으면 빈 배열 반환
                avg_ToS_value = 0;
                return;
            end

            % 첫 번째 연속 셀들을 제외
            start_idx = find(serv_site_idx ~= serv_site_idx(1), 1, 'first');
            if isempty(start_idx)
                ToS_durations = [];  % 모든 셀이 동일하다면 빈 배열 반환
                avg_ToS_value = 0;
                return;
            end

            % 마지막 연속 셀들을 제외
            end_idx = find(serv_site_idx ~= serv_site_idx(end), 1, 'last');
            if isempty(end_idx)
                ToS_durations = [];  % 모든 셀이 동일하다면 빈 배열 반환
                avg_ToS_value = 0;
                return;
            end

            % 중간 구간에 대해서만 계산
            serv_site_idx = serv_site_idx(start_idx:end_idx);

            ToS_durations = [];  % 각 셀에 머문 시간 저장
            count = 1;  % 연속된 셀 카운트
            for i = 2:length(serv_site_idx)
                if serv_site_idx(i) == serv_site_idx(i-1)
                    count = count + 1;  % 같은 셀에 머물면 카운트 증가
                else
                    % 다른 셀로 변경되었을 때 ToS 계산
                    ToS_durations = [ToS_durations, count * sample_time];  % 머문 시간 저장
                    count = 1;  % 카운트 초기화
                end
            end
            % 마지막 셀에 대한 ToS 계산
            ToS_durations = [ToS_durations, count * sample_time];

            % 평균 ToS 계산
            avg_ToS_value = mean(ToS_durations);
        end

        function shortToS_count = calculate_shortToS(obj, serv_site_idx)
            % shortToS 계산 함수 (첫 번째 및 마지막 연속 셀 제외)
            shortToS_count = 0;
            count = 1;

            if length(serv_site_idx) < 3
                return;  % 데이터가 충분하지 않으면 계산하지 않음
            end
        
            % 첫 번째 연속 셀들을 제외
            start_idx = find(serv_site_idx ~= serv_site_idx(1), 1, 'first');
            end_idx = find(serv_site_idx ~= serv_site_idx(end), 1, 'last');
        
            if isempty(start_idx) || isempty(end_idx)
                return;  % 모든 셀이 동일하면 계산하지 않음
            end

            % 중간 구간에 대해서만 계산
            serv_site_idx = serv_site_idx(start_idx:end_idx);
        
            for i = 2:length(serv_site_idx)
                if serv_site_idx(i) == serv_site_idx(i-1)
                    count = count + 1;  % 같은 셀이 연속될 경우 카운트 증가
                else
                    if count < 5
                        shortToS_count = shortToS_count + 1;  % shortToS 카운트 증가
                    end
                    count = 1;  % 카운트 초기화
                end
            end

            % 마지막 그룹에 대해서도 확인
            if count < 5
                shortToS_count = shortToS_count + 1;
            end
        end

        function hopp_count = calculate_HOPP(obj, serv_site_idx)
            % HOPP 계산 함수 (첫 번째 및 마지막 연속 셀 제외)
            hopp_count = 0;
            count = 1;

            if length(serv_site_idx) < 3
                return;  % 데이터가 충분하지 않으면 계산하지 않음
            end

            % 첫 번째 연속 셀들을 제외
            start_idx = find(serv_site_idx ~= serv_site_idx(1), 1, 'first');
            end_idx = find(serv_site_idx ~= serv_site_idx(end), 1, 'last');

            if isempty(start_idx) || isempty(end_idx)
                return;  % 모든 셀이 동일하면 계산하지 않음
            end

            % 중간 구간에 대해서만 계산
            serv_site_idx = serv_site_idx(start_idx:end_idx);
            previous_site = serv_site_idx(1);  % 첫 번째 서빙셀 번호

            temp_site = NaN;  % 임시로 이전 번호와 비교할 셀 번호

            for i = 2:length(serv_site_idx)
                if serv_site_idx(i) == serv_site_idx(i-1)
                    count = count + 1;  % 같은 셀이 연속될 경우 카운트 증가
                else
                    if count < 5
                        if serv_site_idx(i) == previous_site
                            % 연속 5번 미만이면서 다시 이전 셀로 돌아온 경우 HOPP 발생
                            hopp_count = hopp_count + 1;
                        end
                    end
                    % 새로운 셀로 이동했을 경우
                    temp_site = previous_site;  % 현재 셀을 임시 저장
                    previous_site = serv_site_idx(i-1);  % 현재 셀을 이전 셀로 저장
                    count = 1;  % 카운트 초기화
                end
            end

            % 마지막 그룹에 대해서도 확인
            if count < 5 && serv_site_idx(end) == temp_site
                hopp_count = hopp_count + 1;  % 마지막 서빙셀 체크
            end
        end
    end
end

