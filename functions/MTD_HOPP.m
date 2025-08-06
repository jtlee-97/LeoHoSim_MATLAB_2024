% =================================================================
% Winner LAB, Ajou University
% Handover Ping-Pong Protocol Code
% Prototype    : MTD_HOPP.m
% Type         : MATLAB function Code
% Author       : Jongtae Lee
% Revision     : v1.0   2024.06.04
% Modified     : 2024.06.04
% =================================================================

% function ue = MTD_HOPP(ue, current_time)
%     if isempty(ue.hopp_instance)
%         ue.hopp_instance = class_HOPP(ue.SERV_SITE_IDX, current_time);
%     else
%         % Handover occurred to a new site
%         if ue.SERV_SITE_IDX ~= ue.pre_ho_site_idx
%             % Update the post handover information
%             ue.post_ho_site_idx = ue.SERV_SITE_IDX;
%             ue.post_ho_time = current_time;
% 
%             % Check if we returned to the initial site within 1 second
%             if (current_time - ue.pre_ho_time <= 1) && (ue.post_ho_site_idx == ue.hopp_instance.init_site)
%                 ue.HOPP = ue.HOPP + 1;
%                 ue.hopp_instance = []; % Reset HOPP
%             else
%                 % Update the previous site index and time
%                 ue.pre_ho_site_idx = ue.post_ho_site_idx;
%                 ue.pre_ho_time = current_time;
%             end
%         elseif current_time - ue.pre_ho_time > 1
%             % Reset HOPP if the time exceeds 1 second
%             ue.hopp_instance = class_HOPP(ue.SERV_SITE_IDX, current_time);
%         end
%     end
% end
