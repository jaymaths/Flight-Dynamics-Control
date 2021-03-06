P.gravity = 9.81;
   
%physical parameters of airframe
P.mass = 13.5;  %kg
P.Jx   = .8244; %kg*m^2
P.Jy   = 1.135; %kg*m^2
P.Jz   = 1.759; %kg*m^2
P.Jxz  = 1.204; %kg*m^2

P.Gamma = (P.Jx*P.Jz) - (P.Jxz)^2;
P.Gamma1 = (P.Jxz*(P.Jx - P.Jy + P.Jz))/P.Gamma;
P.Gamma2 = (P.Jz*(P.Jz - P.Jy) + (P.Jxz)^2)/P.Gamma;
P.Gamma3 = P.Jz/P.Gamma;
P.Gamma4 = P.Jxz/P.Gamma;
P.Gamma5 = (P.Jz - P.Jx)/P.Jy;
P.Gamma6 = P.Jxz/P.Jy;
P.Gamma7 = ((P.Jz - P.Jy)*P.Jx + (P.Jxz)^2)/P.Gamma;
P.Gamma8 = P.Jx/P.Gamma;

% initial conditions
P.pn0    =  0; % initial North position
P.pe0    =  0; % initial East position
P.pd0    =  0; % initial Down position (negative altitude)
P.u0     =  0; % initial velocity along body x-axis
P.v0     =  0; % initial velocity along body y-axis
P.w0     =  0; % initial velocity along body z-axis
P.phi0   =  0; % initial roll angle
P.theta0 =  0; % initial pitch angle
P.psi0   =  0; % initial yaw angle
P.p0     =  0; % initial body frame roll rate
P.q0     =  0; % initial body frame pitch rate
P.r0     =  0; % initial body frame yaw rate

