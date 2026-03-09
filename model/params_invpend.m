function params = params_invpend()
%PARAMS_INVPEND  Parameter struct for cart-pendulum (upright = 0 rad).

%% A: light pendulum, heavy cart
params.M = 2.4;      % cart mass [kg]
params.m = 0.23;     % pendulum mass [kg]
params.l = 0.4;      % pivot -> COM distance [m]
params.g = 9.81;     % gravity [m/s^2]

% Damping/friction
params.bx = 0.055;   % cart viscous friction [N*s/m]
params.ct = 0.01;    % pivot viscous damping [N*m*s/rad] (tunable)

% Pendulum inertia about COM (rod approx). If rod length L = 2l:
% I_com = (1/12) m L^2 = (1/12) m (2l)^2 = (1/3) m l^2
params.I  = (1/3)*params.m*params.l^2;

% Typical safety/actuator limits (used later by MPC)
params.umax   = 10;              % max force [N]
params.dumax  = 100;             % max force rate [N/s] (we'll convert per Ts later)

params.pmax   = 0.5;             % track half-length [m]     ..... Track / safety constraints
params.vmax   = 2.0;             % cart speed limit [m/s]

params.thetamax = deg2rad(25);   % "regulation envelope" [rad]    ..... indicates that we are solving the stabilization problem

%% B: (“harder”: heavier pendulum, shorter
% Makes stabilization more aggressive + constraints matter more.
% •	(M = 1.0\ \mathrm{kg})
% •	(m = 0.5\ \mathrm{kg})
% •	(l = 0.2\ \mathrm{m})
% •	(b = 0.1\ \mathrm{N,s/m})
% •	(I = \frac{1}{3} m l^2)
%% Set C (“feels underactuated”: lighter cart + longer pendulum)
% Bigger cart motion + slower pendulum dynamics.
% •	(M = 0.5\ \mathrm{kg})
% •	(m = 0.2\ \mathrm{kg})
% •	(l = 0.5\ \mathrm{m})
% •	(b = 0.05\ \mathrm{N,s/m})
% •	(I = \frac{1}{3} m l^2)


end
