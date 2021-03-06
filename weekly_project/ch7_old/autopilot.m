function y = autopilot(uu,P)
%
% autopilot for mavsim
% 
% Modification History:
%   2/11/2010 - RWB
%   5/14/2010 - RWB
%   9/30/2014 - RWB
%   2/12/2016 - WMC
   

    % process inputs
    NN = 0;
    pn       = uu(1+NN);  % inertial North position
    pe       = uu(2+NN);  % inertial East position
    h        = uu(3+NN);  % altitude
    Va       = uu(4+NN);  % airspeed
%    alpha    = uu(5+NN);  % angle of attack
%    beta     = uu(6+NN);  % side slip angle
    phi      = uu(7+NN);  % roll angle
    theta    = uu(8+NN);  % pitch angle
    chi      = uu(9+NN);  % course angle
    p        = uu(10+NN); % body frame roll rate
    q        = uu(11+NN); % body frame pitch rate
    r        = uu(12+NN); % body frame yaw rate
%    Vg       = uu(13+NN); % ground speed
%    wn       = uu(14+NN); % wind North
%    we       = uu(15+NN); % wind East
%    psi      = uu(16+NN); % heading
%    bx       = uu(17+NN); % x-gyro bias
%    by       = uu(18+NN); % y-gyro bias
%    bz       = uu(19+NN); % z-gyro bias
    NN = NN+19;
    Va_c     = uu(1+NN);  % commanded airspeed (m/s)
    h_c      = uu(2+NN);  % commanded altitude (m)
    chi_c    = uu(3+NN);  % commanded course (rad)
    NN = NN+3;
    t        = uu(1+NN);   % time
    
    autopilot_version = 2;
        % autopilot_version == 1 <- used for tuning
        % autopilot_version == 2 <- standard autopilot defined in book
        % autopilot_version == 3 <- Total Energy Control for longitudinal AP
    switch autopilot_version
        case 1,
           [delta, x_command] = autopilot_tuning(Va_c,h_c,chi_c,Va,h,chi,phi,theta,p,q,r,t,P);
        case 2,
           [delta, x_command] = autopilot_uavbook(Va_c,h_c,chi_c,Va,h,chi,phi,theta,p,q,r,t,P);
        case 3,
           [delta, x_command] = autopilot_TECS(Va_c,h_c,chi_c,Va,h,chi,phi,theta,p,q,r,t,P);
        case 4,
           [delta, x_command] = autopilot_points(pn, pe, Va, h, chi,phi,theta,p,q,r,t,P);
    end
    y = [delta; x_command];
end
    
   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Autopilot versions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% autopilot_tuning
%   - used to tune each loop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [delta, x_command] = autopilot_tuning(Va_c,h_c,chi_c,Va,h,chi,phi,theta,p,q,r,t,P)

    mode = 2;
    switch mode
        case 1, % tune the roll loop
            phi_c = chi_c; % interpret chi_c to autopilot as course command
            if t==0,
                delta_a = roll_hold(phi_c, phi, p, 1, P);
            else
                delta_a = roll_hold(phi_c, phi, p, 0, P);
            end                 
            delta_r = 0; % no rudder
            % use trim values for elevator and throttle while tuning the lateral autopilot
            delta_e = P.u_trim(1);
            delta_t = P.u_trim(4);
            theta_c = 0;
        case 2, % tune the course loop
            if t==0,
                flag = 1;
                phi_c   = course_hold(chi_c, chi, r, flag, P);
                delta_a = roll_hold(phi_c, phi, p, flag, P);
                %delta_r = side_slip(beta, flag);
            else
                flag = 0;
                phi_c   = course_hold(chi_c, chi, r, flag, P);
                delta_a = roll_hold(phi_c, phi, p, flag, P);
                %delta_r = side_slip(beta, flag);
            end                
            
             delta_r = 0; % no rudder
            % use trim values for elevator and throttle while tuning the lateral autopilot
            delta_e = P.u_trim(1);
            delta_t = P.u_trim(4);
            theta_c = 0;
        case 3, % tune the throttle to airspeed loop and pitch loop simultaneously
            theta_c = 20*pi/180 + h_c;
            chi_c = 0;
            if t==0,
                flag = 1;
                phi_c   = course_hold(chi_c, chi, r, flag, P);
                delta_t = airspeed_with_throttle_hold(Va_c, Va, flag, P);
                delta_a = roll_hold(phi_c, phi, p, flag, P);
            else
               flag = 0;
                phi_c   = course_hold(chi_c, chi, r, flag, P);
                delta_t = airspeed_with_throttle_hold(Va_c, Va, flag, P);
                delta_a = roll_hold(phi_c, phi, p, flag, P);
            end
            delta_e = pitch_hold(theta_c, theta, q, P);
            %delta_t = P.u_trim(4);
            delta_r = 0; % no rudder
            % use trim values for elevator and throttle while tuning the lateral autopilot
        case 4, % tune the pitch to airspeed loop 
            chi_c = 0;
            delta_t = P.u_trim(4);
            if t==0,
                flag = 1;
                phi_c   = course_hold(chi_c, chi, r, flag, P);
                theta_c = airspeed_with_pitch_hold(Va_c, Va, flag, P);
                delta_a = roll_hold(phi_c, phi, p, flag, P);
            else
               flag = 0;
                phi_c   = course_hold(chi_c, chi, r, flag, P);
                theta_c = airspeed_with_pitch_hold(Va_c, Va, flag, P);
                delta_a = roll_hold(phi_c, phi, p, flag, P);
            end
            
            delta_e = pitch_hold(theta_c, theta, q, P);
            delta_r = 0; % no rudder
            % use trim values for elevator and throttle while tuning the lateral autopilot
        case 5, % tune the pitch to altitude loop 
            chi_c = 0;
            if t==0,
                flag = 1;
                phi_c   = course_hold(chi_c, chi, r, 1, P);
                theta_c = altitude_hold(h_c, h, 1, P);
                delta_t = airspeed_with_throttle_hold(Va_c, Va, flag, P);
                delta_a = roll_hold(phi_c, phi, p, 1, P);
            else
               flag = 0;
                phi_c   = course_hold(chi_c, chi, r, 0, P);
                theta_c = altitude_hold(h_c, h, 0, P);
                delta_t = airspeed_with_throttle_hold(Va_c, Va, flag, P);
                delta_a = roll_hold(phi_c, phi, p, 0, P);
            end
            
            delta_e = pitch_hold(theta_c, theta, q, P);
            delta_r = 0; % no rudder
            % use trim values for elevator and throttle while tuning the lateral autopilot
      end
    %----------------------------------------------------------
    % create outputs
    
    % control outputs
    delta = [delta_e; delta_a; delta_r; delta_t];
    % commanded (desired) states
    x_command = [...
        0;...                    % pn
        0;...                    % pe
        h_c;...                  % h
        Va_c;...                 % Va
        0;...                    % alpha
        0;...                    % beta
        phi_c;...                % phi
        %theta_c*P.K_theta_DC;... % theta
        theta_c;
        chi_c;...                % chi
        0;...                    % p
        0;...                    % q
        0;...                    % r
        ];
            
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% autopilot_uavbook
%   - autopilot defined in the uavbook
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [delta, x_command] = autopilot_uavbook(Va_c,h_c,chi_c,Va,h,chi,phi,theta,p,q,r,t,P)

persistent flag;

    if(t == 0)
        flag = 1;
    else
        flag = 0;
    end

    %----------------------------------------------------------
    % lateral autopilot
  
        % assume no rudder, therefore set delta_r=0
        delta_r = 0;%coordinated_turn_hold(beta, 1, P);
        phi_c   = course_hold(chi_c, chi, r, flag, P);
        delta_a = roll_hold(phi_c, phi, p, flag, P);
   
    %----------------------------------------------------------
    % longitudinal autopilot
    
    % define persistent variable for state of altitude state machine
    persistent altitude_state;
    
    % initialize persistent variable
    if t==0,
        if h<=P.altitude_take_off_zone,     
            altitude_state = 1;
        elseif h<=h_c-P.altitude_hold_zone, 
            altitude_state = 2;
        elseif h>=h_c+P.altitude_hold_zone, 
            altitude_state = 3;
        else
            altitude_state = 4;
        end
        flag = 1;
    end
    
    %disp(altitude_state);
      
    
    % implement state machine
    switch altitude_state,
        case 1,  % in take-off zone
            theta_c = P.takeOffPitch;
            delta_e = pitch_hold(theta_c, theta, q, P);
            delta_t = 1;
            delta_a = roll_hold(0, phi, p, flag, P);
            
            if h>P.altitude_take_off_zone,     
                altitude_state = 2;
            end
            
        case 2,  % climb zone
            theta_c = airspeed_with_pitch_hold(Va_c, Va, flag, P);
            delta_e = pitch_hold(theta_c, theta, q, P);
            delta_t = 1;
            
            if h>=h_c-P.altitude_hold_zone, 
            altitude_state = 4;
            end
            
        case 3, % descend zone
            theta_c = airspeed_with_pitch_hold(Va_c, Va, flag, P);
            delta_e = pitch_hold(theta_c, theta, q, P);
            delta_t = 0;
            
            if h<=h_c+P.altitude_hold_zone, 
            altitude_state = 4;
            end
            
        case 4, % altitude hold zone
            theta_c = altitude_hold(h_c, h, flag, P);
            delta_e = pitch_hold(theta_c, theta, q, P);
            delta_t = airspeed_with_throttle_hold(Va_c, Va, flag, P);
            
            if h<=h_c-P.altitude_hold_zone, 
            altitude_state = 2;
            elseif h>=h_c+P.altitude_hold_zone, 
            altitude_state = 3;
            end
            
    end
    
    
    % artificially saturation delta_t
    delta_t = sat(delta_t,1,0);
    delta_r = 0;
    
    %----------------------------------------------------------
    % create outputs
    
    
    
    % control outputs
    delta = [delta_e; delta_a; delta_r; delta_t];
    % commanded (desired) states
    x_command = [...
        0;...                    % pn
        0;...                    % pe
        h_c;...                  % h
        Va_c;...                 % Va
        0;...                    % alpha
        0;...                    % beta
        phi_c;...                % phi
        %theta_c*P.K_theta_DC;... % theta
        theta_c;
        chi_c;...                % chi
        0;...                    % p
        0;...                    % q
        0;...                    % r
        ];
            
    y = [delta; x_command];
 
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% autopilot_TECS
%   - longitudinal autopilot based on total energy control systems
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [delta, x_command] = autopilot_TECS(Va_c,h_c,chi_c,Va,h,chi,phi,theta,p,q,r,t,P)

    %----------------------------------------------------------
    % lateral autopilot
    if t==0,
        % assume no rudder, therefore set delta_r=0
        delta_r = 0;%coordinated_turn_hold(beta, 1, P);
        phi_c   = course_hold(chi_c, chi, r, 1, P);
        delta_a = roll_hold(phi_c, phi, p, 1, P);

    else
        phi_c   = course_hold(chi_c, chi, r, 0, P);
        delta_r = 0;%coordinated_turn_hold(beta, 0, P);
        delta_a = roll_hold(phi_c, phi, p, 0, P);
    end
         
  
    
    %----------------------------------------------------------
    % longitudinal autopilot based on total energy control
    
    
    delta_e = 0;
    delta_t = 0;
 
    
    %----------------------------------------------------------
    % create outputs
    
    % control outputs
    delta = [delta_e; delta_a; delta_r; delta_t];
    % commanded (desired) states
    x_command = [...
        0;...                    % pn
        0;...                    % pe
        h_c;...                  % h
        Va_c;...                 % Va
        0;...                    % alpha
        0;...                    % beta
        phi_c;...                % phi
        %theta_c*P.K_theta_DC;... % theta
        theta_c;
        chi_c;...                % chi
        0;...                    % p
        0;...                    % q
        0;...                    % r
        ];
            
    y = [delta; x_command];
 
end
   


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Autopilot functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% roll hold (PID Controller)
function [delta_a] = roll_hold(phi_c, phi, p, flag, P)

%tau = .05;

persistent integrator;
%persistent differentiator;
persistent error_d1;

%initialize persistent variables...
if(flag ==1)
    integrator = 0;
    error_d1 = 0;
    %     differentiator = 0;
end

error = phi_c - phi;

%anti-windup + integrator
if (abs(error) < deg2rad(1))
    integrator = integrator + (P.Ts/2)*(error + error_d1);
else
    integrator = 0;
end

%differentiator
% differentiator = (2*tau-P.Ts)/(2*tau+P.Ts)*differentiator...
%     + 2/(2*tau+P.Ts)*(error - error_d1);

error_d1 = error;

%calculate control varible
delta_a = ...
    P.kp_phi*error +...
    P.ki_phi*integrator -...
    P.kd_phi*p;

delta_a = sat(delta_a, P.delta_a_max, -P.delta_a_max); 

end

%% Course Hold (PI controller)
function [phi_c] = course_hold(chi_c, chi, r, flag, P)

persistent integrator;
persistent error_d1;

%initialize persistent variables...
if (flag ==1)
    integrator = 0;
    error_d1 = 0;
end

error = chi_c - chi;

%anti-windup + integrator
if (abs(error) < deg2rad(1))
    integrator = integrator + (P.Ts/2)*(error + error_d1);
else
    integrator = 0;
end

error_d1 = error;

%calculate control varible
phi_c = ...
    P.kp_chi*error +...
    P.ki_chi*integrator - .25*r;

phi_c = sat(phi_c, deg2rad(35), deg2rad(-35));

%delta_a = sat(delta_a, P.delta_a_max, -P.delta_a_max); 

end

%% Side slip (PI control)

function [delta_r] = side_slip(beta_, flag)

persistent integrator
persistent error_d1

beta_c = 0; %no side slip is the default command

error = beta_c - beta_;

if(flag == 1)
   integrator = 0;
end

if(abs(error) < deg2rad(1))
   integrator = integrator + (P.Ts/2)*(error + error_d1);
else
    integrator = 0;
end

error_d1 = error;

delta_r = P.kp_beta*error + P.ki_beta*integrator;

delta_r = sat(delta_r, P.delta_r_max, -P.delta_r_max);

end


%% Airspeed from Throttle Control (PI controller from trim)

function delta_t = airspeed_with_throttle_hold(Va_c, Va, flag, P)


persistent integrator
persistent error_d1

error = Va_c - Va;

if(flag == 1),
   integrator = 0;
end

if(abs(error) < 3)
   integrator = integrator + (P.Ts/2)*(error + error_d1);
else
    integrator = 0;
end

error_d1 = error;

delta_t = P.u_trim(4) + P.kp_v*error + P.ki_v*integrator;

delta_t = sat(delta_t, P.delta_t_max, 0);

end

%% Pitch Hold (PD controller)
function [delta_e] = pitch_hold(theta_c, theta, q, P)

error = theta_c - theta;

%calculate control varible
delta_e = ...
    P.kp_theta*error - P.kd_theta*q;

delta_e = sat(delta_e, P.delta_e_max, -P.delta_e_max); 


end

%% Altitude Hold from Pitch(PI Controller)
function [theta_c] = altitude_hold(h_c, h, flag, P)

persistent integrator;
persistent error_d1;

%initialize persistent variables...
if (flag ==1)
    integrator = 0;
    error_d1 = 0;
end

error = h_c - h;

%anti-windup + integrator
if (abs(error) < 5)
    integrator = integrator + (P.Ts/2)*(error + error_d1);
else
    integrator = 0;
end

error_d1 = error;

%calculate control varible
theta_c = ...
    P.kp_h*error +...
    P.ki_h*integrator;

theta_c = sat(theta_c, deg2rad(30), deg2rad(-3));


end

%% Airspeed from Pitch Control (PI Controller)
function theta_c = airspeed_with_pitch_hold(Va_c, Va, flag, P)


persistent integrator;
persistent error_d1;

%initialize persistent variables...
if (flag ==1)
    integrator = 0;
    error_d1 = 0;
end

error = Va_c - Va;

%anti-windup + integrator
if (abs(error) < 3.5)
    integrator = integrator + (P.Ts/2)*(error + error_d1);
else
    integrator = 0;
end

error_d1 = error;

%calculate control varible
theta_c = ...
    P.kp_v2*error +...
    P.ki_v2*integrator;

theta_c = sat(theta_c, deg2rad(30), deg2rad(-3));

end




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% sat
%   - saturation function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function out = sat(in, up_limit, low_limit)
  if (in > up_limit)
      out = up_limit;
  elseif (in < low_limit)
      out = low_limit;
  else
      out = in;
  end
end



function [delta, x_command] = autopilot_points(pn, pe, Va, h, chi, phi, theta, p, q, r, t, P)
   
    %N, E, H
    points = [500, 0, 200;...
              700, 100, 200;...
              900, 200, 200;...
              200, 1500, 200;...
              0, 1900, 200;...
              -400, 1950, 200;...
              -800, 1950, 200;...
              -1000, 1950, 250;...
              -1200, 1950, 250;...
              -1600, 1930, 200];
     
    persistent STATE;
    
    if(t==0)
        STATE = 0;
        flag = 1;
    else
        flag = 0;
    end
    

    Va_c = 35;
    h_c = points(STATE+1, 3);

    chi_c = get_chi(points(STATE+1, :), [pn pe h]);
    if(chi_c > deg2rad(90) && (chi < deg2rad(-90)))
        chi = deg2rad(360) + chi;
    elseif(chi_c < deg2rad(-90) && (chi > deg2rad(90)))
        chi = -deg2rad(360) - chi;
    end
    pn_c = points(STATE+1,1);
    pe_c = points(STATE+1,2);
    
    if( sqrt((pn_c-pn)^2 + (pe_c-pe)^2 + (h_c-h)^2) < 10)
        STATE = STATE + 1;
        disp('Marker Hit');
    end
    delta_r = 0;%coordinated_turn_hold(beta, 1, P);
    phi_c   = course_hold(chi_c, chi, r, flag, P);
    delta_a = roll_hold(phi_c, phi, p, flag, P);
    
    theta_c = altitude_hold(h_c, h, flag, P);
    delta_e = pitch_hold(theta_c, theta, q, P);
    delta_t = airspeed_with_throttle_hold(Va_c, Va, flag, P);
    
    % control outputs
    delta = [delta_e; delta_a; delta_r; delta_t];
    % commanded (desired) states
    x_command = [...
        pn_c;...                    % pn
        pe_c;...                    % pe
        h_c;...                  % h
        Va_c;...                 % Va
        0;...                    % alpha
        0;...                    % beta
        phi_c;...                % phi
        %theta_c*P.K_theta_DC;... % theta
        theta_c;
        chi_c;...                % chi
        0;...                    % p
        0;...                    % q
        0;...                    % r
        ];
end

function chi = get_chi(nextPoint, currentLocation)
 
pn_c = nextPoint(1);
pe_c = nextPoint(2);
pn = currentLocation(1);
pe = currentLocation(2);


chi = -(atan2(pn_c - pn, pe_c - pe) - (pi/2));

end
 