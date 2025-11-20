%% ev_run.m — Master simulation + data extraction
clear; clc;

% ---------------------------------------------------------
% 1. Load the model
% ---------------------------------------------------------
model = 'EV_Thermal.slx';   % <<< FIXED

disp("Running EV Thermal simulation...");
simOut = sim(model);

% ---------------------------------------------------------
% 2. Extract signals (Timeseries format)
% ---------------------------------------------------------

try
    T      = simOut.T;
    u      = simOut.u;
    u_cmd  = simOut.u_cmd;
    Q_in   = simOut.Q_in;
    Q_act  = simOut.Q_act;
    Q_conv = simOut.Q_conv;
catch
    error("❌ ERROR: One or more To Workspace signals not found. Check names: T, u, u_cmd, Q_in, Q_act, Q_conv.");
end

t     = T.Time;
Tdata = T.Data;

% ---------------------------------------------------------
% 3. Compute metrics
% ---------------------------------------------------------

PeakT     = max(Tdata);
T_final   = Tdata(end);
setpoint  = 35;
SS_error  = T_final - setpoint;

% Settling time (±1°C)
tol = 1;
idx = find(abs(Tdata - setpoint) <= tol,1);

if isempty(idx)
    SettlingTime = NaN;
else
    SettlingTime = t(idx);
end

% ---------------------------------------------------------
% 4. Display results
% ---------------------------------------------------------
fprintf("\n===== EV Thermal Model Results =====\n");
fprintf("Peak Temperature     = %.2f °C\n", PeakT);
fprintf("Final Temperature    = %.2f °C\n", T_final);
fprintf("Steady-state Error   = %.2f °C\n", SS_error);
fprintf("Settling Time (±1°C) = %.2f s\n", SettlingTime);

% ---------------------------------------------------------
% 5. Save results
% ---------------------------------------------------------

if ~exist('results','dir'), mkdir results; end
if ~exist('plots','dir'), mkdir plots; end

save('results/ev_results.mat','T','u','u_cmd','Q_in','Q_act','Q_conv');

disp("Saved results to results/ev_results.mat");

% ---------------------------------------------------------
% 6. Plot Temperature
% ---------------------------------------------------------
figure;
plot(t,Tdata,'LineWidth',1.4);
grid on;
xlabel('Time (s)','FontSize',12);
ylabel('Temperature (°C)','FontSize',12);
title('Battery Pack Temperature Response','FontSize',14);
yline(35,'--r','Setpoint','LineWidth',1.2);

saveas(gcf,'plots/temperature_plot.png');
disp("Saved plot → plots/temperature_plot.png");

