
P.gravity = 9.81;
   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Params for Aersonade UAV
%%physical parameters of airframe
P.mass = 25;
P.Jx   = 0.8244;
P.Jy   = 1.135;
P.Jz   = 1.759;
P.Jxz  = .1204;

P.Gamma = (P.Jx*P.Jz) - (P.Jxz)^2;
P.Gamma1 = (P.Jxz*(P.Jx - P.Jy + P.Jz))/P.Gamma;
P.Gamma2 = (P.Jz*(P.Jz - P.Jy) + (P.Jxz)^2)/P.Gamma;
P.Gamma3 = P.Jz/P.Gamma;
P.Gamma4 = P.Jxz/P.Gamma;
P.Gamma5 = (P.Jz - P.Jx)/P.Jy;
P.Gamma6 = P.Jxz/P.Jy;
P.Gamma7 = ((P.Jz - P.Jy)*P.Jx + (P.Jxz)^2)/P.Gamma;
P.Gamma8 = P.Jx/P.Gamma;

%% aerodynamic coefficients

P.S_wing        = 0.55;
P.b             = 2.8956;
P.c             = 0.18994;
P.S_prop        = 0.2027;
P.rho           = 1.2682;
P.k_motor       = 80;
P.k_T_P         = 0;
P.k_Omega       = 0;
P.e             = 0.9;

P.C_L_0         = 0.28;
P.C_L_alpha     = 3.45;
P.C_L_q         = 0.0;
P.C_L_delta_e   = -0.36;
P.C_D_0         = 0.03;
P.C_D_alpha     = 0.30;
P.C_D_p         = 0.0437;
P.C_D_q         = 0.0;
P.C_D_delta_e   = 0.0;
P.C_m_0         = -0.02338;
P.C_m_alpha     = -0.38;
P.C_m_q         = -3.6;
P.C_m_delta_e   = -0.5;
P.C_Y_0         = 0.0;
P.C_Y_beta      = -0.98;
P.C_Y_p         = 0.0;
P.C_Y_r         = 0.0;
P.C_Y_delta_a   = 0.0;
P.C_Y_delta_r   = -0.17;
P.C_ell_0       = 0.0;
P.C_ell_beta    = -0.12;
P.C_ell_p       = -0.26;
P.C_ell_r       = 0.14;
P.C_ell_delta_a = 0.08;
P.C_ell_delta_r = 0.105;
P.C_n_0         = 0.0;
P.C_n_beta      = 0.25;
P.C_n_p         = 0.022;
P.C_n_r         = -0.35;
P.C_n_delta_a   = 0.06;
P.C_n_delta_r   = -0.032;
P.C_prop        = 1.0;
P.M             = 50;
P.epsilon       = 0.1592;
P.alpha0        = 0.4712;

%% wind parameters

P.wind_n = 0;%3;
P.wind_e = 0;%2;
P.wind_d = 0;
P.L_u = 200;
P.L_v = 200;
P.L_w = 50;
P.sigma_u = 0; %1.06; 
P.sigma_v = 0; %1.06;
P.sigma_w = 0; %.7;

%% Other Coefficients

P.C_p_0     =   P.Gamma3*P.C_ell_0 +    P.Gamma4*P.C_n_0;
P.C_p_beta  =   P.Gamma3*P.C_ell_beta + P.Gamma4*P.C_n_beta;
P.C_p_p     =   P.Gamma3*P.C_ell_p +    P.Gamma4*P.C_n_p;
P.C_p_r     =   P.Gamma3*P.C_ell_r +    P.Gamma4*P.C_n_r;
P.C_p_delta_a = P.Gamma3*P.C_ell_delta_a + P.Gamma4*P.C_n_delta_a;
P.C_p_delta_r = P.Gamma3*P.C_ell_delta_r + P.Gamma4*P.C_n_delta_r;

P.C_r_0     =   P.Gamma4*P.C_ell_0 +    P.Gamma8*P.C_n_0;
P.C_r_beta  =   P.Gamma4*P.C_ell_beta + P.Gamma8*P.C_n_beta;
P.C_r_p     =   P.Gamma4*P.C_ell_p +    P.Gamma8*P.C_n_p;
P.C_r_r     =   P.Gamma4*P.C_ell_r +    P.Gamma8*P.C_n_r;
P.C_r_delta_a = P.Gamma4*P.C_ell_delta_a + P.Gamma8*P.C_n_delta_a;
P.C_r_delta_r = P.Gamma4*P.C_ell_delta_r + P.Gamma8*P.C_n_delta_r;


%% compute trim conditions using 'mavsim_chap5_trim.slx'
% initial airspeed
P.Va0 = 35;
gamma = 0*pi/180;  % desired flight path angle (radians)
R     = inf;         % desired radius (m) - use (+) for right handed orbit, 

%% autopilot sample rate
P.Ts = 0.01;
P.Ts_gps = 1;

%% first cut at initial conditions
P.pn0    = 0;  % initial North position
P.pe0    = 0;  % initial East position
P.pd0    = 0;  % initial Down position (negative altitude)
P.u0     = P.Va0; % initial velocity along body x-axis
P.v0     = 0;  % initial velocity along body y-axis
P.w0     = 0;  % initial velocity along body z-axis
P.phi0   = 0;  % initial roll angle
P.theta0 = 0;  % initial pitch angle
P.psi0   = 0;  % initial yaw angle
P.p0     = 0;  % initial body frame roll rate
P.q0     = 0;  % initial body frame pitch rate
P.r0     = 0;  % initial body frame yaw rate

                    %                          (-) for left handed orbit

%% run trim commands
[x_trim, u_trim]=compute_trim('mavsim_trim',P.Va0,gamma,R);
P.u_trim = u_trim;
P.x_trim = x_trim;

%% set initial conditions to trim conditions
% initial conditions
P.pn0    = 0;  % initial North position
P.pe0    = 0;  % initial East position
P.pd0    = 0;  % initial Down position (negative altitude)
P.u0     = x_trim(4);  % initial velocity along body x-axis
P.v0     = x_trim(5);  % initial velocity along body y-axis
P.w0     = x_trim(6);  % initial velocity along body z-axis
P.phi0   = x_trim(7);  % initial roll angle
P.theta0 = x_trim(8);  % initial pitch angle
P.psi0   = x_trim(9);  % initial yaw angle
P.p0     = x_trim(10);  % initial body frame roll rate
P.q0     = x_trim(11);  % initial body frame pitch rate
P.r0     = x_trim(12);  % initial body frame yaw rate

%% compute different transfer functions
[T_phi_delta_a,T_chi_phi,T_theta_delta_e,T_h_theta,T_h_Va,T_Va_delta_t,T_Va_theta,T_v_delta_r, C]...
    = compute_tf_model(x_trim,u_trim,P);

%% linearize the equations of motion around trim conditions
[A_lon, B_lon, A_lat, B_lat] = compute_ss_model('mavsim_trim',x_trim,u_trim);

A_lon_eig =  eig(A_lon);
A_lat_eig =  eig(A_lat);

Wn_lon_1 = A_lon_eig(1)*A_lon_eig(2)/(2*pi);

Wn_lon_2 = A_lon_eig(3)*A_lon_eig(4)/(2*pi);

%% Compute roll-attitude gains
P.delta_a_max = deg2rad(45);
P.e_phi_max = deg2rad(60);
P.zeda_phi = 1.0;

P.kp_phi = (P.delta_a_max/P.e_phi_max)*sign(C.a_phi_2);

omega_n_phi = sqrt(abs(C.a_phi_2)*P.kp_phi);

P.kd_phi = (2*P.zeda_phi*omega_n_phi - C.a_phi_1)/C.a_phi_2;
P.ki_phi = 0.05;

%% Compute course_hold gains
omega_n_chi = omega_n_phi/10;

P.zeda_chi = 2;

P.kp_chi = 2*P.zeda_chi*omega_n_chi*P.Va0/P.gravity;
P.ki_chi = P.Va0*(omega_n_chi)^2/P.gravity;


%% Compute Side-slip gains
P.delta_r_max = deg2rad(45);
P.e_beta_max = deg2rad(60);
P.zeda_beta = .707;

P.kp_beta = (P.delta_r_max/P.e_beta_max)*sign(C.a_beta_2);
P.ki_beta = (1/(C.a_beta_2))*((C.a_beta_1 + (C.a_beta_2*P.kp_beta))/(2*P.zeda_beta))^2;


%% Pitch gains

zeda_theta = .6;

P.delta_e_max = deg2rad(45);
P.e_theta_max = deg2rad(10);

% [num den] = tfdata(T_theta_delta_e);
% 
% a_theta_3 = num{1}(2);
% a_theta_1 = den{1}(2);
% a_theta_2 = den{1}(3);

P.kp_theta = (P.delta_e_max/P.e_theta_max)*sign(C.a_theta_3);

omega_n_theta = sqrt(C.a_theta_2 + (P.delta_e_max/P.e_theta_max)*abs(C.a_theta_3));

P.kd_theta = (2*zeda_theta*omega_n_theta - C.a_theta_1)/C.a_theta_3;

P.K_theta_dc = (P.kp_theta*C.a_theta_3)/(C.a_theta_2 + P.kp_theta*C.a_theta_3);

%% Compute Throttle to Airspeed gains

% [num, den] = tfdata(T_Va_delta_t);
% 
% a_v_2 = num{1}(2);
% a_v_1 = den{1}(2);

P.delta_t_max = .7;

P.omega_n_v = 10;
P.zeda_v = .707;

P.ki_v = ((P.omega_n_v)^2)/(C.a_v_2);
P.kp_v = (2*P.zeda_v*(P.omega_n_v - C.a_v_1))/C.a_v_2;

%% Compute Altitude from Pitch Gains (section 6.4.2 pg. 108)

P.omega_n_h = omega_n_theta/20;
P.zeda_h = .707;

P.ki_h = (P.omega_n_h)^2/(P.K_theta_dc*P.Va0);
P.kp_h = (2*P.zeda_h*P.omega_n_h)/(P.K_theta_dc*P.Va0);

%% Airspeed from Pitch Gains  (section 6.4.3 pg. 110)

P.omega_n_v2 = omega_n_theta/10;
P.zeda_v2 = .707;

P.ki_v2 = -(P.omega_n_v2)^2/(P.K_theta_dc*P.gravity);
P.kp_v2 = (C.a_v_1 - 2*P.zeda_v2*P.omega_n_v2)/(P.K_theta_dc*P.gravity);


%% Autopilot Stuff
P.takeOffPitch = deg2rad(30);
P.altitude_take_off_zone = 30;
P.altitude_hold_zone = 10;
