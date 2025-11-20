% ========================================================
% ev_analysis.m  — FINAL WORKING VERSION
% ========================================================

model = 'EV_Thermal';
load_system(model);

% ===== Simulation configurations =====
runs = {
    struct('mode',0,'name','cont_PI','Tstop',100,'enable_runaway',0,'mag',1000,'decay',5)
    struct('mode',1,'name','disc_PI','Tstop',100,'enable_runaway',0,'mag',1000,'decay',5)
    struct('mode',0,'name','cont_runaway','Tstop',120,'enable_runaway',1,'mag',1000,'decay',5)
};

results = struct();
outdir = pwd;

for i = 1:numel(runs)

    r = runs{i};
    fprintf('\nRunning %s (mode=%d, runaway=%d) ...\n', r.name, r.mode, r.enable_runaway);

    % update top-level constants
    set_param([model '/mode'],          'Value', num2str(r.mode));
    set_param([model '/enable_runaway'],'Value', num2str(r.enable_runaway));
    set_param([model '/runaway_mag'],   'Value', num2str(r.mag));
    set_param([model '/runaway_decay'], 'Value', num2str(r.decay));
    set_param(model, 'StopTime',        num2str(r.Tstop));

    % run simulation
    simOut = sim(model);

    % =======================================================
    % Extract timeseries
    % =======================================================
    T      = simOut.T;
    u      = simOut.u;
    u_cmd  = simOut.u_cmd;
    Q_in   = simOut.Q_in;
    Q_act  = simOut.Q_act;
    Q_conv = simOut.Q_conv;

    t = T.Time;
    Tdata = T.Data;

    % =======================================================
    % Compute metrics
    % =======================================================
    PeakT = max(Tdata);

    % steady-state = average of last 5%
    N = numel(Tdata);
    tail_start = max(1, floor(0.95*N));
    T_ss = mean(Tdata(tail_start:end));

    % overshoot
    Overshoot = max(0, (PeakT - 35)/35 * 100);

    % settling time (±1°C)
    tol = 1;
    idx = find(abs(Tdata - 35) <= tol, 1);
    if isempty(idx)
        Settling = inf;
    else
        Settling = t(idx);
    end

    % actuator energy
    Energy_act = trapz(t, Q_act.Data);

    % emergency time (u_cmd == 1)
    emergency_mask = (u_cmd.Data >= 0.9);
    emergency_time = sum(emergency_mask) * mean(diff(t));

    % store results
    results.(r.name).t = t;
    results.(r.name).T = Tdata;
    results.(r.name).u_raw = u.Data;
    results.(r.name).u_cmd = u_cmd.Data;
    results.(r.name).Q_in = Q_in.Data;
    results.(r.name).Q_act = Q_act.Data;
    results.(r.name).Q_conv = Q_conv.Data;

    results.(r.name).PeakT = PeakT;
    results.(r.name).T_ss = T_ss;
    results.(r.name).Overshoot = Overshoot;
    results.(r.name).Settling = Settling;
    results.(r.name).Energy_act = Energy_act;
    results.(r.name).Emergency_time = emergency_time;

    % ====== PLOT ======
    figure('Name', r.name);

    subplot(3,1,1);
    plot(t, Tdata,'LineWidth',1.2); grid on;
    yline(35,'--r','Setpoint');
    ylabel('T (°C)');
    title(r.name);

    subplot(3,1,2);
    plot(t, u_cmd.Data,'LineWidth',1.2); hold on;
    plot(t, u.Data,'--','LineWidth',1.2);
    legend('u\_cmd','u\_raw'); grid on;

    subplot(3,1,3);
    plot(t, Q_in.Data,'LineWidth',1.2); hold on;
    plot(t, Q_act.Data,'LineWidth',1.2);
    plot(t, Q_conv.Data,'LineWidth',1.2);
    legend('Q\_in','Q\_act','Q\_conv'); grid on;

    saveas(gcf, fullfile(outdir, [r.name '_summary.png']));

end

% ===== Build results table =====
names = fieldnames(results);
Tpeak = []; Sett = []; Overs = []; Eact = []; EmT = [];

for k = 1:numel(names)
    s = results.(names{k});
    Tpeak(k) = s.PeakT;
    Sett(k)  = s.Settling;
    Overs(k) = s.Overshoot;
    Eact(k)  = s.Energy_act;
    EmT(k)   = s.Emergency_time;
end

tbl = table(names, Tpeak', Sett', Overs', Eact', EmT', ...
    'VariableNames', {'Run','PeakT','Settling','Overshoot','Energy_J','Emergency_s'});

disp(tbl);

writetable(tbl, 'ev_results_table.csv');
save('ev_results.mat', 'results', 'tbl');

fprintf("\nAll runs completed successfully.\n");
