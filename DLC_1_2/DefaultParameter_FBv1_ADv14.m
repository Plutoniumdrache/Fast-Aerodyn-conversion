function [Parameter] = DefaultParameter_FBv1_ADv14(Parameter)
% DS on 03-Feb-2019

%% Pitch Controller
Parameter.CPC.theta_K                   = deg2rad(20);                      % [rad]     % gain scheduling parameter, brute-force-optimized
Parameter.CPC.kp                        = 0.025;                          	% [s]       % proportional gain, brute-force-optimized (adjusted shakti 30.11 educated guess, JP)
Parameter.CPC.Ti                        = 10;                               % [s]       % integral gain, brute-force-optimized

Parameter.CPC.Omega_g_rated             = rpm2radPs(428.5);                 % [rad/s]   % rated generator speed, from Shakti - Geno team 24/11/24 fle
Parameter.CPC.theta_min                 = deg2rad(1.2);                     % [rad]     % pitch angle in region 1-2.5, brute-force optimized
%% Torque Controller
Parameter.VSC.kp                        = 27928.661741;                             % [Nm/(rad/s)]  % proportional gain, first guess (adjusted shakti 10.12 task design script with generator inertia, JP)
Parameter.VSC.Ti                        = 2.196201;                              % [s]           % integral gain, first guess (adjusted shakti 10.12 task design script with generator inertia, JP)
% Parameter.VSC.k                         = 1.9;                              % [Nm/(rad/s)^2]% gain region 2, brute-force-optimized
Parameter.VSC.k                         = .5 * Parameter.General.rho * pi ... % [Nm/(rad/s)^2]% gain region 2, first guess: cp 0.48, lambda 8.75
                                          * Parameter.Turbine.R^5 * .48 / ...
                                          (8.75^3 * Parameter.Turbine.r_GB^3);

P_a_rated  = 5.42e6;                                                        % [W]       % maximal aerodynamic power (can be changed for de- or up-rating), from Shakti(presentation week8) 20/11/24 fle
Parameter.VSC.M_g_rated                 = P_a_rated/Parameter.CPC.Omega_g_rated*Parameter.Turbine.eta_gb;  % [Nm] rated generator torque, from Shakti 21/11/24 fle
Parameter.VSC.i_G_max                   = 1.1;                              % [-]       % ratio for maximum generator torque, standard value
Parameter.VSC.M_g_max                   = Parameter.VSC.M_g_rated*Parameter.VSC.i_G_max;
Parameter.VSC.Omega_g_1d5               = rpm2radPs(300);                   % [rad/s]   % generator speed during region 1.5, from Shakti(excel) 20/11/24 fle         

Parameter.VSC.Delta_Omega_g             = 0.10*Parameter.CPC.Omega_g_rated; % [rad/s]   % over-/under-speed limit for setpoint-fading, first guess
Parameter.VSC.Delta_theta               = deg2rad(20);                      % [rad]     % change of pitch angle at which under-speed limit should be reached, brute-force-optimized
Parameter.VSC.Delta_P                   = 5e6;                          	% [W]       % change of power at which over-speed limit should be reached, first guess

%% Filter Generator Speed
Parameter.Filter.LowPass.Enable         = 1;                                % [0/1]     % flag to enable low pass filter for generator speed
Parameter.Filter.LowPass.f_cutoff       = 1;                                % [Hz]      % cut-off-frequency for low pass filter for generator speed, first guess
Parameter.Filter.LowPass2.f_cutoff     	= 0.02;                             % [Hz]      % cut-off-frequency for low pass filter for setpoint-fading, first guess
Parameter.Filter.LowPass3.f_cutoff      = 0.01;                             % [Hz]      % cut-off-frequency for low pass filter for dynamic notch filter, first guess
Parameter.Filter.NotchFilter.Enable   	= 1;                                % [0/1]     % flag to enable dynamic notch filter for generator speed
Parameter.Filter.NotchFilter.Gain       = 3/Parameter.Turbine.r_GB;         % [-]       % gain on generator rotational frequency for dynamic notch filter, standard value
Parameter.Filter.NotchFilter.BW      	= 0.10;                             % [Hz]      % bandwidth of dynamic notch filter, first guess
Parameter.Filter.NotchFilter.D       	= 0.01;                             % [-]       % depth of dynamic notch filter, first guess
                             
%% helper functions
function y = rpm2radPs(u)
    y = u * 2*pi/60;

end

end


