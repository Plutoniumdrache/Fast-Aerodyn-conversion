function [Parameter] = DefaultParameter_PitchActuator(Parameter)
% DS on 03-Feb-2019
% Values from Pietro
Parameter.PitchActuator.omega           = pi;               % [rad/s]   % frequency
Parameter.PitchActuator.xi              = 0.8;              % [-]       % damping    
Parameter.PitchActuator.theta_dot_max 	= deg2rad(2);       % [rad/s]   % max/min pitch rate
Parameter.PitchActuator.theta_max     	= deg2rad(90);      % [rad]     % max pitch angle
Parameter.PitchActuator.theta_min     	= deg2rad(0);       % [rad]     % min pitch angle
end