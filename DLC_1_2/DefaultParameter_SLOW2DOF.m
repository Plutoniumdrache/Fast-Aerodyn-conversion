function [Parameter] = DefaultParameter_SLOW2DOF
% DS on 11-Jun-2020

%% General          
Parameter.General.rho               = 1.12;         	% [kg/m^3]  air density, from requirments list

%% Turbine
Parameter.Turbine.SS             	= load('PowerAndThrustCoefficients_SHAKTI_v5.mat','c_P','c_T','theta','lambda'); % from simulations
          
Parameter.Turbine.r_GB              = 53.37;            % [-]       gearbox ratio, from ElastoDyn.dat:1/GBRatio, from Eslam 20/11/24 fle 
Parameter.Turbine.R              	= 178/2;            % [m]       Rotor radius, from ElastoDyn.dat: TipRad, from Shakti(Carlo table) 20/11/24 fle  

% drive-train dynamics
J_G                               	= 860;          % [kgm^2]	Generator Inertia About High-Speed Shaft, from ElastoDyn.dat: GenIner (shakti just a guess 10.12, JP)
J_R                                	= 98167088;         % [kgm^2]	Rotor Inertia About High-Speed Shaft, from ED.sum file (shakti 10.12 from sum file, JP)
Parameter.Turbine.J                	= J_R+J_G*Parameter.Turbine.r_GB^2;
Parameter.Turbine.eta_gb            = 0.955;            % [-]       Gearbox efficiency, from ElastoDyn.dat: GBoxEff

% fore-aft tower dynamics  
d_s                                 = 0.01;             % [-]       Structural Damping ratio from ElastoDyn_Tower.dat (shakti 29.11 DLC 1.2 FAST, JP)
f_0TwFADOF1                         = 0.305;            % [Hz]      Undamped tower fore-aft eigenfrequency, from Bortolotti2019
Parameter.Turbine.x_T0           	= -0.0880;          % [m]       static tower top displacement, from steady states
Parameter.Turbine.k_Te            	= 1.81e+06;         % [kg/s^2]  tower equivalent bending stiffness, from steady states
Parameter.Turbine.m_Te          	= Parameter.Turbine.k_Te/(f_0TwFADOF1*2*pi)^2;     	% [kg]      tower equivalent modal mass
Parameter.Turbine.c_Te            	= 2*Parameter.Turbine.m_Te*d_s*f_0TwFADOF1*2*pi;    % [kg/s]	tower structual damping (sigma=C_T/(2M_T)=D*w_0, w_0=f_0*2*pi, [Gasch] p.294)
Parameter.Turbine.HubHeight         = 140.4374;           % [m]       TowerHt+Twr2Shft+OverHang*sind(ShftTilt) (shakti 29.11 DLC 1.2 FAST, JP)

%% Generator
Parameter.Generator.eta_el      	= 0.9659;             % [-]     (from slides 10.12 shakti) eta genertor*converter*transformer*cables = 0.98*0.98*0.99*0.99 

end