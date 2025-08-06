% =================================================================
% Winner LAB, Ajou University
% Distance-based HO Parameter Optimization Protocol Code
% Prototype    : class_History.m
% Type         : MATLAB Class
% Author       : Jongtae Lee
% Revision     : v1.0   2024.06.04
% Modified     : 2024.06.04
% =================================================================

classdef class_History
    properties
        LOC_X = [];
        LOC_Y = [];
        INTF_TOTAL_mwatt = [];
        INTF_TOTAL_dB = [];
        SERV_SITE_IDX = [];
        ENV_DIS = [];
        ENV_ANG = [];
        ENV_ELEV = [];
        ML = [];
        Xp = [];
        LOSS = [];
        AGGAIN = [];
        SINR = [];
        SNR = [];
        SIR = [];
        RSRP_dBm = [];
        RSRP_dBm_rec = [];
        RSRP_mW = [];
        HO = []; % Adding HO to track handovers
        RBs = [];
        HOPP = []; % Adding HOPP to track handover ping-pongs
        RLF = [];
        ToS = []; % Time of Stay
        UHO = []; % Unstable Handover
        DELAY;
        PACKET_LOSS;
    end

    methods
        function obj = update(obj, ue)
            obj.LOC_X = [obj.LOC_X; ue.LOC_X];
            obj.LOC_Y = [obj.LOC_Y; ue.LOC_Y];
            obj.INTF_TOTAL_mwatt = [obj.INTF_TOTAL_mwatt; ue.INTF_TOTAL_mwatt];
            obj.INTF_TOTAL_dB = [obj.INTF_TOTAL_dB; ue.INTF_TOTAL_dB];
            obj.SERV_SITE_IDX = [obj.SERV_SITE_IDX; ue.SERV_SITE_IDX];
            obj.ENV_DIS = [obj.ENV_DIS; ue.ENV_DIS];
            obj.ENV_ANG = [obj.ENV_ANG; ue.ENV_ANG];
            obj.ENV_ELEV = [obj.ENV_ELEV; ue.ENV_ELEV];
            obj.ML = [obj.ML; ue.ML];
            obj.Xp = [obj.Xp; ue.Xp];
            obj.LOSS = [obj.LOSS; ue.LOSS];
            obj.AGGAIN = [obj.AGGAIN; ue.AGGAIN];
            obj.SINR = [obj.SINR; ue.SINR(ue.SERV_SITE_IDX)];
            obj.SNR = [obj.SNR; ue.SNR];
            obj.SIR = [obj.SIR; ue.SIR];
            obj.RSRP_dBm = [obj.RSRP_dBm; ue.RSRP_dBm];
            obj.RSRP_dBm_rec = [obj.RSRP_dBm_rec; ue.RSRP_dBm(ue.SERV_SITE_IDX)];
            obj.RSRP_mW = [obj.RSRP_mW; ue.RSRP_mW];
            obj.HO = [obj.HO; ue.HO];
            obj.RBs = [obj.RBs; ue.RBs];
            obj.HOPP = [obj.HOPP; ue.HOPP];
            obj.RLF = [obj.RLF; ue.RLF];
            obj.DELAY = [obj.DELAY; ue.DELAY];
            obj.PACKET_LOSS = [obj.PACKET_LOSS; ue.PACKET_LOSS];
        end

        function obj = calculate_ToS(obj, sample_time)
            unique_sites = unique(obj.SERV_SITE_IDX);
            tos = zeros(length(unique_sites), 1);

            for i = 1:length(unique_sites)
                site_idx = unique_sites(i);
                stay_time = sum(obj.SERV_SITE_IDX == site_idx) * sample_time;
                tos(i) = stay_time;
            end

            obj.ToS = containers.Map(num2cell(unique_sites), num2cell(tos));
        end
        
        function obj = calculate_UHO(obj)
            uho_count = 0;
            
            % SERV_SITE_IDX에서 처음과 마지막 셀 번호를 가져옴
            first_site = obj.SERV_SITE_IDX(1);
            last_site = obj.SERV_SITE_IDX(end);
            
            % 처음과 마지막 셀 번호를 제외한 배열을 만들기
            trimmed_site_idx = obj.SERV_SITE_IDX(obj.SERV_SITE_IDX ~= first_site & obj.SERV_SITE_IDX ~= last_site);
        
            % Trimmed 배열이 비어있는 경우 UHO를 0으로 설정하고 리턴
            if isempty(trimmed_site_idx)
                obj.UHO = uho_count;
                return;
            end
        
            prev_site = trimmed_site_idx(1);  % 첫 번째 셀 시작
            count = 1;
        
            % Trimmed 배열에 대해 반복
            for i = 2:length(trimmed_site_idx)
                if trimmed_site_idx(i) == prev_site
                    count = count + 1;
                else
                    if count <= 5
                        uho_count = uho_count + 1;
                    end
                    prev_site = trimmed_site_idx(i);
                    count = 1;
                end
            end
        
            % 마지막 사이트에서의 카운트 처리
            if count <= 5
                uho_count = uho_count + 1;
            end
        
            obj.UHO = uho_count;
        end

    end
end
