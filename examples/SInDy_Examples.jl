using DataDrivenDiffEq
using ModelingToolkit
using DifferentialEquations
using Plots
gr()

# Create a test problem
function pendulum(u, p, t)
    x = u[2]
    y = -9.81sin(u[1]) - 0.1u[2]
    return [x;y]
end

u0 = [0.2π; -1.0]
tspan = (0.0, 40.0)
prob = ODEProblem(pendulum, u0, tspan)
sol = solve(prob)

plot(sol)

# Create the differential data
DX = similar(sol[:,:])
for (i, xi) in enumerate(eachcol(sol[:,:]))
    DX[:,i] = pendulum(xi, [], 0.0)
end

# Create a basis
@variables u[1:2]
polys = [u[1]^0]
for i ∈ 1:3
    for j ∈ 1:3
        push!(polys, u[1]^i*u[2]^j)
    end
end

h = [1u[1];1u[2]; cos(u[1]); sin(u[1]); u[1]*u[2]; u[1]*sin(u[2]); u[2]*cos(u[2]); polys...]

[ui for ui in u]

basis = Basis(h, u, parameters = [])

#Generate eqs
Ψ = SInDy(sol[:,:], DX, basis, ϵ = 1e-2, maxiter = 100)

# Simulate
estimator = ODEProblem(Ψ.f_, u0, tspan)
sol_ = solve(estimator, saveat = sol.t)
norm(sol-sol_)