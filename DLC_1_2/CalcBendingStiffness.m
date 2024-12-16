% -----------------------------
% Script: Tool to plot the openfast result file.
% In this raw version the windspeed, rotational speed, Power and tower top
% deflection are plotted. See OutListParameters.xlsx for a listing of available output channels
% ------------
% Modified:
% 
% ------------
% History: 
% Felix Lehmann on 29-09-2024
% ----------------------------------
% References:
% - used model: IEA-3.4-130-RWT
% - code based on: SummerGames2024 IEA Task52

clearvars;close all;

%% select wind speed range
wind = 3:0.1:9; % wind speed range
%% Generate FAST simulation outputs
tic
for i = 1:length(wind)
    
    % find parameter placeholder in inflow file and replace with wind speed
    windstr = num2str(wind(i),'%02.1f');
    filename = 'TemplateIEA-3.4-130-RWT_InflowFile.dat';
    new_filename = 'IEA-3.4-130-RWT_InflowFile.dat';
    S = fileread(filename);
    S = regexprep(S, 'PlaceholderWind', windstr); % replace with wind speed
    fid = fopen(new_filename, 'w');
    fwrite(fid, S);
    fclose(fid);
    
    % run FAST
    dos('.\openfast_x64.exe IEA-3.4-130-RWT.fst');
    
    % rename output and move file to output directory
    OutputFile  = 'IEA-3.4-130-RWT.out';
     
    new_filename = "OutputFiles\" + "IEA-3.4-130-RWT" + num2str(wind(i),'%02.1f') + ".out";
    movefile(OutputFile,new_filename);
end
toc
%% PostProcessing FAST
V_test = wind;

StadyStatesFAST.v_0     = zeros(1,length(V_test));
StadyStatesFAST.Omega   = zeros(1,length(V_test));
StadyStatesFAST.theta   = zeros(1,length(V_test));
StadyStatesFAST.x_t     = zeros(1,length(V_test));
StadyStatesFAST.M_g     = zeros(1,length(V_test));
StadyStatesFAST.F_a     = zeros(1,length(V_test));


for idx = 1:length(V_test)
    FileName = ['IEA-3.4-130-RWT',num2str(V_test(idx),'%02.1f')];
    OutputFileFAST = ['OutputFiles\',FileName,'.out'];
%     [Channels, ChanName, ChanUnit, FileID, DescStr] =  ReadFASTbinary(OutputFileFAST);

    fid         = fopen(OutputFileFAST);
    formatSpec  = repmat('%f',1,16);
    FASTResults = textscan(fid,formatSpec,'HeaderLines',8);
    Time        = FASTResults{:,1};
    Wind1VelX   = FASTResults{:,2};
    RotSpeed    = FASTResults{:,6};
    TTDspFA     = FASTResults{:,7};
    TwrTpTDxi   = FASTResults{:,12};
    YawBrTDxp   = FASTResults{:,13};
    LSShftFxa   = FASTResults{:,14};
    GenPwr      = FASTResults{:,15};
    fclose(fid);

    % last 3 revolutions
    Omega_end   = RotSpeed(end)/60;             % [1/s]
    t_3Rev      = 3 * Omega_end^-1;             % [s]
    dt_FAST     = 0.0125;                       % [s]
    index_t     = round(t_3Rev/dt_FAST);        % [-]

    % Mean of the last 3 revolutions
    % windspeed
    StadyStatesFAST.v_0(idx) = mean(Wind1VelX(index_t:end));
    % Omega
    StadyStatesFAST.Omega(idx) = mean(RotSpeed(index_t:end));    % [rpm]
    % theta
%     StadyStatesFAST.theta(idx) = mean(BldPitch1(index_t:end));   % [deg]
    % Tower top deflection
    StadyStatesFAST.x_t(idx)    = mean(TTDspFA(index_t:end));      % [m]
    StadyStatesFAST.x_ti(idx)   = mean(TwrTpTDxi(index_t:end));      % [m]
    StadyStatesFAST.x_tp(idx)   = mean(YawBrTDxp(index_t:end));      % [m]
    % Generator torque 
%     StadyStatesFAST.M_g(idx) = mean(GenTq(index_t:end));         % [kNm]
    % Aerodynamic force
%     StadyStatesFAST.F_a(idx) = mean(RtAeroFxi(index_t:end));         % [N] only in aerodyn v15 supported  
    StadyStatesFAST.LSShftFxa(idx)   = mean(LSShftFxa(index_t:end)*1000); % [N] % this one leads to the correct initial tower top deflection
    % if you want to know why you need to dig into the aerodyn module...
end
%% Plot FAST Steady States
figure('Name','x_T')
hold on;grid on;box on;
% plot(v_0,x_T,'.')
plot(StadyStatesFAST.v_0,StadyStatesFAST.x_t,'.')
xlabel('v_0 [m/s]')
ylabel('x_T [m]')
% legend('SLOW','FAST','Location','southeast')

figure('Name','F_a')
hold on;grid on;box on;
% plot(StadyStatesFAST.v_0,StadyStatesFAST.F_a,'.','Color','b') % only in aerodyn v15 supported
plot(StadyStatesFAST.v_0,StadyStatesFAST.LSShftFxa,'.','Color','r')
xlabel('Time [s]')
ylabel('F_a [N]')
% legend('Aerodyn15','Elastodyn','Location','southeast') % only in aerodyn v15 supported

cut = 0;
x_t = StadyStatesFAST.x_t(1:end-cut);
x_ti = StadyStatesFAST.x_ti(1:end-cut);
x_tp = StadyStatesFAST.x_tp(1:end-cut);
% F_a = StadyStatesFAST.F_a(1:end-cut); % only in aerodyn v15 supported
F_a_elastodyn = StadyStatesFAST.LSShftFxa(1:end-cut);

figure('Name','tower equvivalent bending stiffness')
hold on;box on;grid on;
plot(x_t,F_a_elastodyn)
plot(x_ti,F_a_elastodyn)
plot(x_tp,F_a_elastodyn)
xlabel('TTDspFA tower top position [m]')
ylabel('RtAeroFxi [N]')
legend('TTDspFA','TwrTpTDxi','YawBrTDxp')

format compact;
% inital tower top deflection from basic fit of F_a over x_t for zero force
x_T0 = -0.021 % [m]
k_Te = F_a_elastodyn./(x_t-x_T0);
k_Te = mean(k_Te)
