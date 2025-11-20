%% scripts/make_final_plots.m
% Run 4 scenarios and save comparison plots

model = 'EV_Thermal.slx';
if exist('results','dir')~=7, mkdir('results'); end
if exist('plots','dir')~=7, mkdir('plots'); end

cases = {
  struct('name','cont_normal','mode',0,'runaway',0,'Tstop',100), ...
  struct('name','cont_runaway','mode',0,'runaway',1,'Tstop',120), ...
  struct('name','disc_normal','mode',1,'runaway',0,'Tstop',100), ...
  struct('name','disc_runaway','mode',1,'runaway',1,'Tstop',120) ...
};

allData = struct();

for k=1:numel(cases)
    c = cases{k};
    fprintf('Running: %s\n', c.name);
    set_param('EV_Thermal/mode','Value',num2str(c.mode));
    set_param('EV_Thermal/enable_runaway','Value',num2str(c.runaway));
    simOut = sim(model,'StopTime',num2str(c.Tstop),'SaveOutput','on','SaveFormat','Structure');

    Tts = simOut.T;
    time = Tts.Time;
    temp = Tts.Data;

    % save mat per run
    save(fullfile('results',[c.name,'.mat']),'time','temp','c');

    % simple plot
    figure('Visible','off'); plot(time,temp,'LineWidth',1.4); grid on;
    xlabel('Time (s)'); ylabel('Temperature (°C)');
    title(['Temperature — ' c.name],'Interpreter','none');
    yline(35,'--r','Setpoint','LineWidth',1.0);
    saveas(gcf,fullfile('plots',[c.name,'.png']));
    close(gcf);

    % store for comparison
    allData.(c.name) = struct('time',time,'temp',temp);
end

% Overlay plot: normal controllers (continuous vs discrete)
figure('Visible','off');
plot(allData.cont_normal.time, allData.cont_normal.temp,'-','LineWidth',1.6); hold on;
plot(allData.disc_normal.time, allData.disc_normal.temp,'--','LineWidth',1.4);
yline(35,'--r','Setpoint','LineWidth',1);
grid on; xlabel('Time (s)'); ylabel('Temperature (°C)');
legend('Continuous (normal)','Discrete (normal)','Location','best');
title('Controller Comparison — Normal Load');
saveas(gcf,'plots/comp_normal.png'); close(gcf);

% Overlay plot: runaway controllers (continuous vs discrete)
figure('Visible','off');
plot(allData.cont_runaway.time, allData.cont_runaway.temp,'-','LineWidth',1.6); hold on;
plot(allData.disc_runaway.time, allData.disc_runaway.temp,'--','LineWidth',1.4);
yline(35,'--r','Setpoint','LineWidth',1);
grid on; xlabel('Time (s)'); ylabel('Temperature (°C)');
legend('Continuous (runaway)','Discrete (runaway)','Location','best');
title('Controller Comparison — Runaway Event');
saveas(gcf,'plots/comp_runaway.png'); close(gcf);

% Save a summary CSV
Tpeak = [max(allData.cont_normal.temp), max(allData.cont_runaway.temp), max(allData.disc_normal.temp), max(allData.disc_runaway.temp)];
Tfinal = [allData.cont_normal.temp(end), allData.cont_runaway.temp(end), allData.disc_normal.temp(end), allData.disc_runaway.temp(end)];
tbl = table({'cont_normal';'cont_runaway';'disc_normal';'disc_runaway'}, Tpeak', Tfinal', 'VariableNames', {'Case','PeakT','FinalT'});
writetable(tbl,'results/summary_table.csv');

fprintf('Plots saved in ./plots and summary_table.csv in ./results\n');
