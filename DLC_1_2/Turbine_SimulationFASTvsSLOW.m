% -----------------------------
% Script: Tests pitch controller at different operation points.
% Exercise 03 of "Controller Design for Wind Turbines and Wind Farms"
% -----------------------------

clearvars;clc;close all;
clear all;
%% PreProcessing SLOW for all simulations

% Default Parameter Turbine and Controller
Parameter                       = DefaultParameter_SLOW2DOF;
Parameter                       = DefaultParameter_PitchActuator(Parameter);
Parameter                       = DefaultParameter_FBv1_ADv14(Parameter);

% Time
dt                              = 1/80;
Parameter.Time.dt               = dt;   % [s] simulation time step              
Parameter.Time.TMax             = 80;   % [s] simulation length

%% Loop over Operation Points
    
OPs = [7];
step = 0;
nOP = length(OPs);

for iOP=1:nOP
    
    % get Operation Point
    OP = OPs(iOP);

    % wind for this OP
    Disturbance.v_0.time            = [0; 30; 30+dt;  60];       % [s]      time points to change wind speed
    Disturbance.v_0.signals.values  = [0;  0;  step; step]+OP;    % [m/s]    wind speeds

    % Initial Conditions from SteadyStates for this OP
    SteadyStates = load('SteadyStatesShakti5MW_classic.mat','v_0','Omega','theta','M_g','x_T');                       
    Parameter.IC.Omega          	= interp1(SteadyStates.v_0,SteadyStates.Omega,OP,'linear','extrap');
    Parameter.IC.theta          	= interp1(SteadyStates.v_0,SteadyStates.theta,OP,'linear','extrap');
    Parameter.IC.M_g          	    = interp1(SteadyStates.v_0,SteadyStates.M_g,  OP,'linear','extrap');
    Parameter.IC.x_T          	    = interp1(SteadyStates.v_0,SteadyStates.x_T,  OP,'linear','extrap');

    % Processing SLOW for this OP
    simout = sim('FBv1_SLOW2DOF.mdl');
    
    % collect simulation Data
    Omega(:,iOP)    = simout.logsout.get('y').Values.Omega.Data;
    M_g(:,iOP)      = simout.logsout.get('y').Values.M_g.Data;
    Power_el(:,iOP) = simout.logsout.get('y').Values.P_el.Data;
    lambda(:,iOP)   = simout.logsout.get('y').Values.lambda.Data;
    theta(:,iOP)    = simout.logsout.get('y').Values.theta.Data;
    v_0(:,iOP)      = simout.logsout.get('d').Values.v_0.Data;
    c_P(:,iOP)     = simout.logsout.get('y').Values.c_P.Data;

end

tout = simout.tout;

%% Run FAST simulations to compare
% run aerodynV15 or V14
aerodynV15 = 0; % 1 = V15, 0 = V14
if 0 == step
wind = OPs;
% find parameter placeholder in inflow file and replace with wind speed
    windstr = num2str(wind,'%2f');
    filename = 'TemplateIEA-3.4-130-RWT_InflowFile.dat';
    new_filename = 'IEA-3.4-130-RWT_InflowFile.dat';
    S = fileread(filename);
    S = regexprep(S, 'PlaceholderWind', windstr); % replace with wind speed
    fid = fopen(new_filename, 'w');
    fwrite(fid, S);
    fclose(fid);
end
if aerodynV15
    % run FAST with aerodyn V15
    dos('.\openfast_x64.exe IEA-3.4-130-RWT_AD15.fst');
    % rename output and move file to output directory
    OutputFile  = 'IEA-3.4-130-RWT_AD15.out';
else
    % run FAST with aerodyn V14
    dos('.\openfast_x64.exe IEA-3.4-130-RWT_AD14.fst');
    % rename output and move file to output directory
    OutputFile  = 'IEA-3.4-130-RWT_AD14.out';
end
    


%% PostProcessing FAST
if aerodynV15
    fid         = fopen(OutputFile);
    formatSpec  = repmat('%f',1,18);
    FASTResults = textscan(fid,formatSpec,'HeaderLines',8);
    Time        = FASTResults{:,1};
    Wind1VelX   = FASTResults{:,2};
    BldPitch1   = FASTResults{:,5};
    RotSpeed    = FASTResults{:,6};
    RtAeroCp    = FASTResults{:,15}; % only supported by aerodyn v15
    RtTSR       = FASTResults{:,16}; % only supported by aerodyn v15
    GenPwr      = FASTResults{:,17}; 
    GenTq       = FASTResults{:,18};
else
    fid         = fopen(OutputFile);
    formatSpec  = repmat('%f',1,16);
    FASTResults = textscan(fid,formatSpec,'HeaderLines',8);
    Time        = FASTResults{:,1};
    Wind1VelX   = FASTResults{:,2};
    BldPitch1   = FASTResults{:,5};
    RotSpeed    = FASTResults{:,6};
    GenPwr      = FASTResults{:,15};
    GenTq       = FASTResults{:,16};
    fclose(fid);
end
%% PostProcessing SLOW
figure
subplot(511)
hold on;box on;grid on;
plot(tout,Omega*60/2/pi)
plot(Time, RotSpeed)
ylabel('\Omega [rpm]')
if aerodynV15
    legend('SLOW','FAST AD15','Location','southeast')
else
    legend('SLOW','FAST AD14','Location','southeast')
end

subplot(512)
hold on;box on;grid on;
plot(tout,rad2deg(theta))
plot(Time, BldPitch1)
ylabel('\theta [°]')
if aerodynV15
    legend('SLOW','FAST AD15','Location','southeast')
else
    legend('SLOW','FAST AD14','Location','southeast')
end

subplot(513)
hold on;box on;grid on;
plot(tout,M_g./1000)
plot(Time,GenTq)
ylabel('M_g [kNm]')
if aerodynV15
    legend('SLOW','FAST AD15','Location','southeast')
else
    legend('SLOW','FAST AD14','Location','southeast')
end

subplot(514)
hold on;box on;grid on;
plot(tout,Power_el./1000)
plot(Time,GenPwr)
ylabel('Power [kW]')
if aerodynV15
    legend('SLOW','FAST AD15','Location','southeast')
else
    legend('SLOW','FAST AD14','Location','southeast')
end

subplot(515)
hold on;box on;grid on;
plot(tout,v_0)
plot(Time,Wind1VelX)    
ylabel('v_0 [m/s]')
if aerodynV15
    legend('SLOW','FAST AD15','Location','southeast')
else
    legend('SLOW','FAST AD14','Location','southeast')
end

if aerodynV15
    figure
    subplot(211)
    title('c_P')
    hold on;box on;grid on;
    plot(tout,c_P)
    plot(Time,RtAeroCp)    
    ylabel('')
    legend('SLOW','FAST AD15','Location','southeast')
    
    subplot(212)
    title('lambda')
    hold on;box on;grid on;
    plot(tout,lambda)
    plot(Time,RtTSR)    
    ylabel('')
    legend('SLOW','FAST AD15','Location','southeast')
end