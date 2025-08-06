% =================================================================
% Winner LAB, Ajou University
% Handover Class Definition
% Prototype    : class_Handover.m
% Type         : MATLAB Class
% Author       : Jongtae Lee
% Revision     : v1.1   2024.08.29  % 날짜 수정
% Modified     : 2024.08.29  % 수정 날짜 업데이트
% =================================================================

% classdef class_Handover
%     properties
%         preparation_state;
%         execution_state;
%         prep_time;
%         exec_time;
%         serv_idx;
%         targ_idx;
%         TTT_check;
%         exec_TTT_check;
%         last_ho_time;
%         last_site_idx;
%         Xp_locked;
%         Xp_locked_next;
%         PD_check;  % 전파 지연 타이머 속성 추가
%         valid_indices;  % 필터링된 후보 셀 인덱스
%     end
% 
%     methods
%         % Handover 객체 생성
%         function obj = class_Handover(serv_idx)
%             obj.preparation_state = false;
%             obj.execution_state = false;
%             obj.prep_time = 0;
%             obj.exec_time = 0;
%             obj.serv_idx = serv_idx;
%             obj.targ_idx = 0;
%             obj.TTT_check = 0;
%             obj.exec_TTT_check = 0;
%             obj.last_ho_time = 0;
%             obj.last_site_idx = 0;
%             obj.Xp_locked = false; % 초기화
%             obj.Xp_locked_next = false; % 초기화
%             obj.PD_check = 0;  % 전파 지연 타이머 초기화
%             obj.valid_indices = [];  % 필터링된 후보 셀 인덱스 초기화
%         end
% 
%         % Handover 준비 상태 초기화
%         function obj = initiate_preparation(obj, current_time, new_targ_idx)
%             obj.preparation_state = true;
%             obj.prep_time = current_time;
%             obj.targ_idx = new_targ_idx;
%         end
% 
%         % Handover 실행 상태 초기화
%         function obj = initiate_execution(obj, current_time)
%             obj.execution_state = true;
%             obj.exec_time = current_time;
%         end
% 
%         % Handover 객체 초기화
%         function obj = reset(obj, new_serv_idx)
%             obj.preparation_state = false;
%             obj.execution_state = false;
%             obj.prep_time = 0;
%             obj.exec_time = 0;
%             obj.serv_idx = new_serv_idx;
%             obj.targ_idx = 0;
%             obj.TTT_check = 0;
%             obj.exec_TTT_check = 0;
%             obj.PD_check = 0;  % PD 타이머 초기화
%             obj.Xp_locked = false; % 초기화
%             obj.Xp_locked_next = false; % 초기화
%             obj.valid_indices = [];  % 후보 셀 인덱스 초기화
%         end
% 
%         % 전파 지연 타이머 초기화 메서드 추가
%         function obj = PD_reset(obj)
%             obj.PD_check = 0;  % 전파 지연 타이머 초기화
%         end
%     end
% end

classdef class_Handover
    properties
        preparation_state;
        execution_state;
        prep_time;
        exec_time;
        serv_idx;
        targ_idx;
        TTT_check;
        exec_TTT_check;
        last_ho_time;
        last_site_idx;
        Xp_locked;
        Xp_locked_next;
        PD_check;
        valid_indices;  % 필터링된 후보 셀 인덱스 저장
    end

    methods
        % Handover 객체 생성
        function obj = class_Handover(serv_idx)
            obj.preparation_state = false;
            obj.execution_state = false;
            obj.prep_time = 0;
            obj.exec_time = 0;
            obj.serv_idx = serv_idx;
            obj.targ_idx = 0;
            obj.TTT_check = 0;
            obj.exec_TTT_check = 0;
            obj.last_ho_time = 0;
            obj.last_site_idx = 0;
            obj.Xp_locked = false;
            obj.Xp_locked_next = false;
            obj.PD_check = 0;
            obj.valid_indices = [];  % 후보 셀 인덱스 초기화
        end

        % Handover 준비 상태 설정
        function obj = initiate_preparation(obj, current_time, new_targ_idx)
            obj.preparation_state = true;
            obj.prep_time = current_time;
            obj.targ_idx = new_targ_idx;
        end

        % Handover 실행 상태 설정
        function obj = initiate_execution(obj, current_time)
            obj.execution_state = true;
            obj.exec_time = current_time;
        end

        % Handover 상태 초기화
        function obj = reset(obj, new_serv_idx)
            obj.preparation_state = false;
            obj.execution_state = false;
            obj.prep_time = 0;
            obj.exec_time = 0;
            obj.serv_idx = new_serv_idx;
            obj.targ_idx = 0;
            obj.TTT_check = 0;
            obj.exec_TTT_check = 0;
            obj.PD_check = 0;
            obj.Xp_locked = false;
            obj.Xp_locked_next = false;
            obj.valid_indices = [];  % 후보 셀 인덱스 초기화
        end

        % 후보 셀 인덱스를 업데이트
        function obj = update_valid_indices(obj, valid_idx)
            obj.valid_indices = valid_idx;  % 후보 셀 인덱스 업데이트
        end

        % 후보 셀 인덱스를 리셋
        function obj = reset_valid_indices(obj)
            obj.valid_indices = [];  % 후보 셀 인덱스 초기화
        end
    end
end
