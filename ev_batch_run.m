%% ev_batch_run.m — Run all 4 validation cases
clear; clc;

cases = {
    'Continuous Controller, Normal Load', 0, 0;   % mode, enable_runaway
    'Continuous Controller, Runaway',     0, 1;
    'Discrete Controller, Normal Load',   1, 0;
    'Discrete Controller, Runaway',       1, 1
};

results = [];

for k = 1:size(cases,1)

    fprintf("\n==== Running Case %d: %s ====\n", ...
        k, cases{k,1});

    mode_value = cases{k,2};
    runaway    = cases{k,3};

    % Set variables
    assignin('base','mode',mode_value);
    assignin('base','enable_runaway',runaway);

    % Run simulation
    simOut = sim('EV_Thermal.slx');

    % Extract temperature
    T  = simOut.T;
    t  = T.Time;
    Td = T.Data;

    % Metrics
    PeakT = max(Td);
    FinalT = Td(end);
    SS_err = FinalT - 35;

    % Settling time ±1°C
    idx = find(abs(Td - 35) <= 1,1);
    if isempty(idx)
        Settling = NaN;
    else
        Settling = t(idx);
    end

    results = [results; PeakT, FinalT, SS_err, Settling];

end

% Save final table
colNames = {'PeakT','FinalT','SS_error','SettlingTime'};
ResultsTable = array2table(results,'VariableNames',colNames);

writetable(ResultsTable,'results/batch_results.csv');

fprintf("\nSaved → results/batch_results.csv\n");
