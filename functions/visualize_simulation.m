% =================================================================
% Winner LAB, Ajou University
% Distance-based HO Parameter Optimization Protocol Code
% Prototype    : visualize_simulation.m
% Type         : MATLAB function Code
% Author       : Jongtae Lee
% Revision     : v1.0   2024.06.04
% Modified     : 2024.06.04
% =================================================================

function visualize_simulation(sat, ue_array, TIMEVECTOR, histories, sat_histories)
    figure;
    hold on;
    title('Simulation Visualization (v 1.4)')
    updateInterval = 0.01; % Update interval in seconds, lower value for faster animation
    radius = 25000 / 1000;  % Convert to km
    
    xlabel('X (km)');
    ylabel('Y (km)');
    axis equal; 
    grid on;

    % Plot UE initial positions
    for i = 1:numel(ue_array)
        plot(ue_array(i).LOC_X / 1000, ue_array(i).LOC_Y / 1000, 'ro', 'MarkerFaceColor', 'r');  % Convert to km
    end

    h = plot(sat_histories(1).BORE_X(1, :) / 1000, sat_histories(1).BORE_Y(1, :) / 1000, 'k*', 'MarkerSize', 3); % Initial positions, Convert to km
    textHandles = gobjects(1, size(sat_histories(1).BORE_X, 2)); % Initialize text handles
    circleHandles = gobjects(1, size(sat_histories(1).BORE_X, 2)); % Initialize circle handles

    for traj_idx = 1:length(sat_histories)
        for idx = 1:5:length(TIMEVECTOR)  % Update every 5th frame for faster animation
            % Update SAT positions for visualization
            set(h, 'XData', sat_histories(traj_idx).BORE_X(idx, :) / 1000, 'YData', sat_histories(traj_idx).BORE_Y(idx, :) / 1000);  % Convert to km

            if exist('circleHandles', 'var') && ~isempty(circleHandles)
                delete(circleHandles);
            end

            if exist('textHandles', 'var') && ~isempty(textHandles)
                delete(textHandles);
            end

            circleHandles = gobjects(1, size(sat_histories(traj_idx).BORE_X, 2));
            textHandles = gobjects(1, size(sat_histories(traj_idx).BORE_X, 2));

            for j = 1:size(sat_histories(traj_idx).BORE_X, 2)
                circleHandles(j) = rectangle('Position', [sat_histories(traj_idx).BORE_X(idx, j) / 1000 - radius, ...
                    sat_histories(traj_idx).BORE_Y(idx, j) / 1000 - radius, 2 * radius, 2 * radius], ...
                    'Curvature', [1, 1], 'EdgeColor', "#E0CBF2", 'LineStyle', '-', 'LineWidth', 0.0001);

                % Add text annotations with index numbers
                textHandles(j) = text(sat_histories(traj_idx).BORE_X(idx, j) / 1000, sat_histories(traj_idx).BORE_Y(idx, j) / 1000, num2str(j), ...
                    'Color', 'black', 'FontSize', 8, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');
            end
            drawnow limitrate; % Update the figure with limited rate
        end
    end
    hold off;
end
