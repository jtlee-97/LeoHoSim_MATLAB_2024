% ==========================    =======================================
% Winner LAB, Ajou University
% Distance-based HO Parameter Optimization Protocol Code
% Prototype    : system_parameter.m
% Type         : MATLAB code
% Author       : Jongtae Lee
% Revision     : v1.0   2024.06.04
% Modified     : 2024.07.01
% =================================================================

%% Set1-600km Scenario
cellRadius = 23120;  %25000, 23120
cellISD = 40045.0147; % 43301.2702, 40045.0147

%% User Equipment Configuration
% UE_num = 251; % 26, 251

UE_x = randi([0, cellRadius], 1, 100); % 랜덤 UE 위치 생성
% UE_x = 17340; % RSRP용 centre, mid, edge 위치별 (10000km, 17340m, 23120m)
UE_y = 80090.0293; % 86602.5404, 80090.0293


%% General Parameter
FREQ = 2e9;                                     % 2GHz [Frequency band]
BW = 20e6;                                      % 20 MHz [Bandwidth]
c = 299792458;                                  % light speed
BOLTZ = 1.38064852e-23;                         % Boltzmann constant [J/K]
Tx_g = 30;
AP = 2;
eirp = 34;
altit = 600000;

%% Filtering Parameters
% k_filter = 2; % SINR 필터용 k 개수
k_rsrp = 0;   % RSRP 필터 계수 설정 (가중치 고려 (이전값/현재값), 0: 0%/100% | 2: 30%/70% | 4: 50%/50% | 8: 75%/25%

%% Simulation Time Configuration
START_TIME = 0;                 % 시작 시간 0초
SAT_SPEED = 7560;
TOTAL_TIME = 173.21 / 7.56;      % 64.95, 86.6, 129.9, 173.2, 216.5
SAMPLE_TIME = 0.2;                              % 10ms: measurement epoch 
STOP_TIME = TOTAL_TIME;                         % 총 시뮬레이션 시간
SITE_MOVE = SAT_SPEED * SAMPLE_TIME;            % moving distance (deterministic)
TIMEVECTOR = 0:SAMPLE_TIME:STOP_TIME;           % Create time vector

%% Simulation Episode Set
EPISODE = 1;                                   % SIMULATION EPISODE
Scenario_ = 'case 1';
fading = 'Rural';
% fading = 'Urban';
% fading = 'DenseUrban';