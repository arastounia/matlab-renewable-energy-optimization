%% Task 3: PV + Storage for 3 hours

clear all
close all

%% Data
PV   = [0 4 3 1 0];
Load = [1 1 1 1 1];

Buy  = [0.25 0.25 0.75 0.25 0.25];   % €/kWh grid purchase
Sell = [0.1 0.1 0.1 0.1 0.1];   % €/kWh feed-in tariff

SOC_0   = 0;     % initial SOC
SOC_end = 0;     % final SOC (can also be 10 depending on assignment)
SOC_min = 1;
SOC_max = 10;

Pbat_min = -3;     % discharge
Pbat_max =  3;     % charge

N = 5;

%% Variables: for each hour i
% x1(i) = battery power (+charge, -discharge)
% x2(i) = grid purchase
% x3(i) = grid feed-in
% x4(i) = SOC

n = 4*N;
idx = @(k,i) 4*(i-1)+k;

%% Objective f^T x
f = zeros(n,1);
for i = 1:N
    f(idx(2,i)) = Buy(i);      % purchase cost
    f(idx(3,i)) = -Sell(i);    % feed-in revenue
end

%% Equality constraints Aeq x = beq
% Power balance: PV + purchase = Load + feed + battery
% -> x1 + x3 - x2 = PV - Load

Aeq = zeros(2*N+1, n);
beq = zeros(2*N+1, 1);

row = 0;

% Power balance
for i = 1:N
    row = row + 1;
    Aeq(row, idx(1,i)) =  1;
    Aeq(row, idx(3,i)) =  1;
    Aeq(row, idx(2,i)) = -1;
    beq(row)           = PV(i) - Load(i);
end

% SOC dynamics
% First hour
row = row + 1;
Aeq(row, idx(4,1)) =  1;
Aeq(row, idx(1,1)) = -1;
beq(row)           = SOC_0;

% Hours 2..N
for i = 2:N
    row = row + 1;
    Aeq(row, idx(4,i))   =  1;
    Aeq(row, idx(4,i-1)) = -1;
    Aeq(row, idx(1,i))   = -1;
    beq(row)             =  0;
end

% Final SOC
row = row + 1;
Aeq(row, idx(4,N)) = 1;
beq(row)           = SOC_end;

%% Bounds
lb = -inf(n,1);
ub =  inf(n,1);

for i = 1:N
    lb(idx(1,i)) = Pbat_min; 
    ub(idx(1,i)) = Pbat_max;

    lb(idx(2,i)) = 0; % purchase >=0
    lb(idx(3,i)) = 0; % feed-in >=0

    lb(idx(4,i)) = SOC_min;
    ub(idx(4,i)) = SOC_max;
end

%% Solve
[x, fval] = linprog(f, [],[], Aeq, beq, lb, ub);

disp('Optimal solution found:')
x
fval
