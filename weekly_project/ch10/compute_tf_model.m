function [T_phi_delta_a,T_chi_phi,T_theta_delta_e,T_h_theta,T_h_Va,T_Va_delta_t,T_Va_theta,T_v_delta_r, C]...
    = compute_tf_model(x_trim,u_trim,P)
%% Map Inputs
% x_trim is the trimmed state,
% u_trim is the trimmed input

u_speed_trim = x_trim(4);
w_trim = x_trim(6);
Va_trim = sqrt(x_trim(4)^2 + x_trim(5)^2 + x_trim(6)^2);

theta_trim = x_trim(8);
psi_trim = x_trim(9);

delta_e_trim = u_trim(1);
delta_t_trim = u_trim(4);

%% Lateral Transfer Functions (setup)
%roll (pg. 69)
a_phi1 = -(1/2)*P.rho*((Va_trim)^2)*P.S_wing*P.b*P.C_p_p*(P.b/(2*(Va_trim)));
a_phi2 = (1/2)*P.rho*((Va_trim)^2)*P.S_wing*P.b*P.C_p_delta_a;

%yaw (pg. 71)
a_beta1 = ((-P.rho*Va_trim*P.S_wing)/(2*P.mass))*P.C_Y_beta;
a_beta2 = ((-P.rho*Va_trim*P.S_wing)/(2*P.mass))*P.C_Y_delta_r;

%% Longitudinal Transfer Functions (setup)
%pitch (pg. 73)
a_theta1 = -(P.rho*(Va_trim)^2*P.c*P.S_wing/(2*P.Jy))*P.C_m_q*(P.c/(2*Va_trim));
a_theta2 = -(P.rho*(Va_trim)^2*P.c*P.S_wing/(2*P.Jy))*P.C_m_alpha;
a_theta3 = (P.rho*(Va_trim)^2*P.c*P.S_wing/(2*P.Jy))*P.C_m_delta_e;

%airspeed (pg. 77)
a_V1 = (P.rho*Va_trim*P.S_wing/P.mass)*(P.C_D_0 + P.C_D_alpha*atan(w_trim/u_speed_trim)...
    + P.C_D_delta_e*delta_e_trim) + (P.rho*P.S_prop/P.mass)*P.C_prop*Va_trim;
a_V2 = (P.rho*P.S_prop/P.mass)*P.C_prop*((P.k_motor)^2)*delta_t_trim;
a_V3 = P.gravity*cos(theta_trim - psi_trim);

%% Contants Struct

C.a_phi_1 = a_phi1;
C.a_phi_2 = a_phi2;
C.a_beta_1 = a_beta1;
C.a_beta_2 = a_beta2;
C.a_theta_1 = a_theta1;
C.a_theta_2 = a_theta2;
C.a_theta_3 = a_theta3;
C.a_v_1 = a_V1;
C.a_v_2 = a_V2;
C.a_v_3 = a_V3;


%% Define transfer functions
T_phi_delta_a   = tf([a_phi2],[1,a_phi1,0]);
T_chi_phi       = tf([P.gravity/Va_trim],[1,0]);
T_theta_delta_e = tf(a_theta3,[1,a_theta1,a_theta2]);
T_h_theta       = tf([Va_trim],[1,0]);
T_h_Va          = tf([theta_trim],[1,0]);
T_Va_delta_t    = tf([a_V2],[1,a_V1]);
T_Va_theta      = tf([-a_V3],[1,a_V1]);
T_v_delta_r     = tf([Va_trim*a_beta2],[1,a_beta1]);

