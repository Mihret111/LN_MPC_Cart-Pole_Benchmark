function test_model_sanity()
params = params_invpend();

% Linearization check
[A,B] = linearize_upright(params);

Ts = 0.02;
[Ad,Bd] = discretize_zoh(A,B,Ts);

fprintf('eig(Ad):\n');
disp(eig(Ad).');

% Nonlinear sim quick test (open-loop u=0)
x = [0; 0; deg2rad(5); 0];   % small 5 deg initial angle
dt = 1e-3;
Tend = 2.0;
N = round(Tend/dt);

X = zeros(4,N+1); X(:,1) = x;
t = (0:N)*dt;

for k=1:N
    u = 0;
    % simple RK4
    k1 = f_nl(x, u, params);
    k2 = f_nl(x + 0.5*dt*k1, u, params);
    k3 = f_nl(x + 0.5*dt*k2, u, params);
    k4 = f_nl(x + dt*k3, u, params);
    x  = x + (dt/6)*(k1 + 2*k2 + 2*k3 + k4);
    X(:,k+1) = x;
end

figure; plot(t, X(3,:)); grid on;
xlabel('t [s]'); ylabel('\theta [rad]');
title('Open-loop nonlinear: upright is unstable (should diverge)');

end
