# LEO Handover Simulation Platform for 5G NTN (LeoHoSim_MATLAB_2024)

![MATLAB](https://img.shields.io/badge/MATLAB-R2024a%2B-orange)
![License](https://img.shields.io/badge/License-Custom-red.svg)

A comprehensive MATLAB-based simulation platform for evaluating and optimizing handover algorithms in 5G Non-Terrestrial Networks (NTN) with Low Earth Orbit (LEO) satellite constellations.

## 🚀 Overview

This project provides a time-step based simulator designed to model 5G NTN scenarios with a focus on **handover optimization**. It implements a LEO satellite constellation at a 600 km altitude with Earth-moving cell scenarios, following the specifications outlined in 3GPP TR 38.821.

The core purpose of this platform is to evaluate hybrid handover mechanisms that combine signal strength measurements (A3-based), distance calculations (D2-based), and temporal parameters to enhance handover performance, reliability, and efficiency in dynamic satellite networks.

### ✨ Key Features

* **LEO Constellation Model:** Simulates a 127-beam satellite constellation at 600 km altitude.
* **3GPP Compliant:** Adheres to NTN specifications from 3GPP TR 38.821.
* **Advanced Handover Algorithms:** Implements and compares multiple A3-based and Distance-based handover methods, including conditional handover (CHO) variants.
* **Realistic RF Modeling:** Includes detailed path loss models for various environments (Rural, Urban), shadowing, and circular aperture satellite antenna gain patterns.
* **Network Event Detection:** Features modules for detecting Radio Link Failures (RLF) using the T310 timer and Handover Ping-Pong (HOPP) events.
* **Comprehensive Analytics:** A powerful analytics engine processes simulation data to generate key performance indicators (KPIs) like SINR, RSRP, Handover Rate, Time of Stay (ToS), RLF Rate, and Ping-Pong Rate.

---

## 🏗️ System Architecture

The simulator is built on a modular architecture with five primary subsystems that work together to model, execute, and analyze handover scenarios.

```mermaid
graph TD
    A[Core Simulation Engine] --> B{Handover Management};
    A --> C{Signal Processing};
    A --> D{Event Management};
    B --> E{Analytics Engine};
    C --> B;
    D --> B;
````

1.  **Core Components (`/classes`)**: Models the fundamental entities of the network, including User Equipment (`class_UE`), Satellites (`class_SAT`), Handover State (`class_Handover`), and Data Logging (`class_History`).
2.  **Signal Processing (`/functions`)**: Manages all RF calculations, such as path loss (`GET_LOSS`), antenna gain (`GET_AGGAIN`), and geometric calculations (distance, elevation).
3.  **Handover Algorithms (`/functions`)**: Contains the decision logic for all implemented handover methods (`MTD_A3_*`, `MTD_D2_*`).
4.  **Event Management (`/classes`)**: Detects and manages network failures and inefficiencies, including Radio Link Failures (`class_RLF`) and Ping-Pong events (`class_HOPP`).
5.  **Analytics Engine (`/classes`)**: Processes raw data from simulations to generate final performance metrics (`class_EpisodeResult`, `class_FinalResult`).

-----

## 🛰️ Core Simulation Components

The simulation engine is built around four fundamental MATLAB classes that model the physical and logical aspects of the 5G NTN system.

| Component           | Primary Class      | Purpose                  | Key Responsibilities                                     |
| :------------------ | :----------------- | :----------------------- | :------------------------------------------------------- |
| **User Equipment** | `class_UE`         | Mobile device modeling   | Mobility, signal processing, state management, L3 filtering |
| **Satellite Network** | `class_SAT`        | Satellite characteristics | Orbital data, antenna parameters, transmit power (EIRP) |
| **Handover Mgmt** | `class_Handover`   | Handover state machine   | State transitions, algorithm execution, timer management (TTT) |
| **History Tracking**| `class_History`    | Data collection          | Logging performance metrics and network events per time-step |

-----

## 🔄 Handover Decision Algorithms

The platform's primary function is to compare different handover strategies. The algorithms are grouped into two main categories.

### 📶 A3-Based Handover Methods

These algorithms trigger handovers based on the 3GPP **A3 event**, where a neighbor cell's signal strength (RSRP) exceeds the serving cell's signal by a configured offset for a certain Time-to-Trigger (TTT).

  * `MTD_A3_BHO`: A basic, direct implementation of the A3 event handover.
  * `MTD_A3_CHO`: A Conditional Handover (CHO) implementation with a two-stage (preparation and execution) process, allowing for more robust decisions in dynamic environments. Several revised variants (`_rev`, `_rev2`, `_rev3`) explore optimizations like filtered RSRP, top-N candidate selection, and enhanced target validation.

### 📏 Distance-Based Handover Methods

These methods use geometric distance (Maximum Likelihood - ML) as the primary handover criterion, which is often more predictable in LEO scenarios than fluctuating RSRP.

  * `MTD_D2_HO`: A basic distance-based handover triggered when the serving satellite's distance exceeds a threshold relative to neighbors.
  * `MTD_D2_HO_3gpp`: Implements dual-condition, threshold-based triggering that aligns more closely with 3GPP standards.

-----

## 📊 Analytics and Performance Metrics

The simulator provides a robust analytics pipeline to evaluate algorithm performance. The `class_FinalResult` object contains the aggregated results for a full simulation run.

**Key Performance Indicators (KPIs):**

  * **Signal Quality**: Average SINR (`final_avg_SINR`) and RSRP (`final_avg_RSRP`).
  * **Handover Performance**:
      * Average Handover Count (`final_avg_HO`)
      * Average Time of Stay (`final_avg_ToS`)
      * Unnecessary Handover Rate (`final_avg_UHO`)
      * Handover Ping-Pong Rate (`final_avg_HOPP`)
  * **Network Reliability**:
      * Radio Link Failure Rate (`final_avg_RLF`)
      * Average Delay and Packet Loss (`final_avg_Delay`, `final_avg_PACKET_LOSS`)
  * **Resource Utilization**: Total Resource Blocks (`RBs`) used for handover signaling.

-----

## 🚀 Getting Started

### Prerequisites

  * MATLAB R2024a or newer.
  * No special toolboxes are required.

### Configuration

Before running a simulation, you can adjust the core parameters in the following files:

  * `system_parameter.m`: Defines key system-level parameters like satellite EIRP, antenna aperture (`AP`), transmit gain (`Tx_g`), and orbital altitude (`altit`).
  * `system_61_site.m`: Contains the `x` and `y` ground coordinates for the 61-satellite constellation beams.

### Running a Simulation

1.  Configure your desired handover algorithm and its parameters (e.g., `Offset_A3`, `TTT`) in the main simulation script (e.g., `main.m`).
2.  Run the main script from the MATLAB command window:

<!-- end list -->

```matlab
% In main.m (example setup)

% Simulation parameters
NUM_EPISODES = 10;
SIMULATION_TIME = 120; % seconds
UE_SPEED = 3; % m/s

% Algorithm selection
handover_algorithm = 'MTD_A3_CHO_rev3';
params.Offset_A3 = 3; % dB
params.TTT = 40; % ms

% Run the simulation
final_results = run_simulation(handover_algorithm, params, NUM_EPISODES, ...);

% Display results
disp('Simulation Complete!');
disp(['Average Handover Count: ', num2str(final_results.final_avg_HO)]);
disp(['Average SINR (dB): ', num2str(final_results.final_avg_SINR)]);
disp(['Ping-Pong Rate: ', num2str(final_results.final_avg_HOPP)]);
```

### Project Structure

```
.
├── classes/
│   ├── class_UE.m
│   ├── class_SAT.m
│   ├── class_Handover.m
│   ├── class_History.m
│   ├── class_RLF.m
│   ├── class_HOPP.m
│   ├── class_EpisodeResult.m
│   └── class_FinalResult.m
├── functions/
│   ├── MTD_A3_BHO.m
│   ├── MTD_A3_CHO.m
│   ├── MTD_D2_HO.m
│   ├── GET_LOSS.m
│   ├── GET_AGGAIN.m
│   └── ...
├── config/
│   ├── system_parameter.m
│   └── system_61_site.m
├── main.m                % Example main simulation script
└── README.md
```

### 🚀 Quick Start
1) Configure Parameters
Open the system_parameter.m file to review and modify key simulation variables, such as satellite altitude, number of satellites, and number of UEs.

2) Review the Process (Optional)
You can inspect the overall simulation procedure and detailed logic in the system_process.m file.

3) Run the Simulation
In MATLAB, open the system_start.m file and press the Run button, or type system_start in the command window to begin the simulation.

-----

## 🤝 Contributing & Contact

Contributions, questions, and collaboration inquiries are welcome. For any questions regarding this simulator, please contact the maintainer.

**Jongtae Lee** (Ph.D. Candidate)  
Wireless Internet aNd Network Engineering Research (WINNER) Lab  
Dept. of Artificial Intelligence Convergence Network  
Ajou University, Suwon, Republic of Korea

  * **E-mail:** [jtlee830@ajou.ac.kr](mailto:jtlee830@ajou.ac.kr)
  * **Phone:** +82-(0)31-219-2474
  * **Homepage:**
    1.  **Lab:** [https://winner.ajou.ac.kr/](https://winner.ajou.ac.kr/)
    2.  **Personal CV:** [https://sites.google.com/view/jongtaelee-cv/introduce](https://sites.google.com/view/jongtaelee-cv/introduce)

## 📜 License & Usage Policy

This project is fundamentally licensed under the permissive terms of the MIT License (included below), but with an additional usage policy for specific academic and research purposes.

### 1. General Use (Based on MIT License)

This software may be freely used, copied, modified, and forked for personal learning, study, or non-commercial testing purposes under the MIT License. All copies of the software must include the original copyright and permission notices.

### 2. Use for Academic Projects or Publications

If you intend to use this simulator or its components for specific purposes that will result in a formal output, such as a **research project, thesis/dissertation, or an academic publication**, the following additional conditions apply:

1.  **Prior Contact is Required**: You **must** contact the maintainer, Jongtae Lee, via email at  at [jtlee830@ajou.ac.kr](mailto:jtlee830@ajou.ac.kr) (or [2jongtae@gmail.com](mailto:2jongtae@gmail.com)) to notify and discuss your intended use if you plan to fork this work to start a new project or request a dedicated branch.

2.  **Agreement on Acknowledgment:** For any resulting publications or formal works, appropriate credit, citation, or **co-authorship** must be discussed and mutually agreed upon to properly reflect the contribution of this work.

<!-- end list -->

---
*© LeoHoSim_MATLAB_2024 (Jongtae Lee, @jtlee-97) — All Rights Reserved.*
```
