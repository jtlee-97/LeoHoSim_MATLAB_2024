% =================================================================
% Winner LAB, Ajou University
% Distance-based HO Parameter Optimization Protocol Code
% Prototype    : GET_DIS_ANG.m
% Type         : MATLAB function Code
% Author       : Jongtae Lee
% Revision     : v1.0   2024.06.04
% Modified     : 2024.06.04
% =================================================================

function [distances, angles, elevs] = GET_DIS_ANG(BORE_X, BORE_Y, SAT_ALTITUDE, UE_LOC_X, UE_LOC_Y, UE_ALTITUDE)
    num_bore = numel(BORE_X);

    % Calculate distances
    dx = BORE_X - UE_LOC_X;
    dy = BORE_Y - UE_LOC_Y;
    dz = SAT_ALTITUDE - UE_ALTITUDE;
    distances = sqrt(dx.^2 + dy.^2 + dz.^2);

    % Calculate angles
    bore_positions = [BORE_X; BORE_Y; repmat(SAT_ALTITUDE, 1, num_bore)];
    bore_ground = [BORE_X; BORE_Y; zeros(1, num_bore)];
    ue_position = [repmat(UE_LOC_X, 1, num_bore); repmat(UE_LOC_Y, 1, num_bore); repmat(UE_ALTITUDE, 1, num_bore)];

    u_VECTOR = bore_positions - bore_ground;
    v_VECTOR = bore_positions - ue_position;

    dot_product = sum(u_VECTOR .* v_VECTOR);
    u_norm = sqrt(sum(u_VECTOR.^2));
    v_norm = sqrt(sum(v_VECTOR.^2));
    angle_radians = acos(dot_product ./ (u_norm .* v_norm));
    angles = rad2deg(angle_radians);

    % Calculate elevations
    elevs = GET_UV_ELEV(distances, SAT_ALTITUDE);
end
