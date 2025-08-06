% =================================================================
% Winner LAB, Ajou University
% Distance-based HO Parameter Optimization Protocol Code
% Prototype    : system_61_site.m
% Type         : MATLAB code
% Author       : Jongtae Lee
% Revision     : v1.0   2024.06.27
% Modified     : 2024.06.27
% =================================================================

function [x, y] = generateHexagonalCells(radius, tiers)
    x = 0; 
    y = 0;
    for tier = 1:tiers
        for side = 0:5
            for step = 0:tier-1
                angle = (side * 60 + 30) * pi / 180;
                dx = radius * sqrt(3) * (tier * cos(angle) - step * sin(angle + pi/6));
                dy = radius * sqrt(3) * (tier * sin(angle) + step * cos(angle + pi/6));
                x = [x; dx];
                y = [y; dy];
            end
        end
    end
end

function plotHexagon(x, y, radius)
    angles = (0:60:360) * pi / 180;
    hx = x + radius * cos(angles);
    hy = y + radius * sin(angles);
    plot(hx, hy, 'k-');
end

% 메인 스크립트
tiers = 6;  % 4-tier까지 확장
run('system_parameter.m');
[x, y] = generateHexagonalCells(cellRadius, tiers);
% 
% % % % % 각 좌표 간 거리 계산
% index1 = 1; % 1번 셀
% index3 = 3; % 3번 셀
% distance_1_3 = sqrt((x(index1) - x(index3))^2 + (y(index1) - y(index3))^2);
% disp(['ISD ', num2str(index1), ' and ', num2str(index3), ': ', num2str(distance_1_3)]);
% % 
% % 10번과 23번 셀의 y좌표들의 중앙 계산
% index10 = 10;
% index16 = 16;
% y_mid = (y(index10) + y(index16)) / 2;
% disp(['UE start Y', num2str(index10), ' and cell ', num2str(index16), ': ', num2str(y_mid)]);
% disp(['Y #10 ', num2str(index10), ': ', num2str(y(index10))]);
% disp(['Y #16 ', num2str(index16), ': ', num2str(y(index16))]);
% 
% 그래프 표시 (필요시 주석 해제)
% figure;
% hold on;
% for i = 1:length(x)
%     plotHexagon(x(i), y(i), cellRadius);
%     text(x(i), y(i), num2str(i), 'HorizontalAlignment', 'center');
%     plot(x(i), y(i), 'r-o');
% end
% %scatter(x, y, 'r', 'filled');
% axis equal;
% title(['Hexagonal Cell Layout (', num2str(tiers), ' tiers)']);
% xlabel('X coordinate');
% ylabel('Y coordinate');
% grid on;

% disp([x, y]);
% disp(['Total number of cells: ', num2str(length(x))]);
