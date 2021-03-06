using DataDrivenDiffEq
using ModelingToolkit
using DifferentialEquations
using LinearAlgebra
using Plots
gr()



# Create a basis of functions aka observables ( aka features )
@variables u[1:2]
h = [u[1]; sin(u[1]); sin(u[2]); u[2]; u[1]*u[2]; u[2]^2]
basis = Basis(h, u)

# Create a test system
function test_discrete(du, u, p, t)
    du[1] = 0.9u[1] + 0.1u[2]^2
    du[2] = sin(u[1]) - 0.1u[1]
end

# Set up the problem
u0 = [1.0; 2.0]
tspan = (0.0, 50.0)
prob = DiscreteProblem(test_discrete, u0, tspan)
sol = solve(prob)
# Plot the solution
# plot(sol)


# Build the edmd with subset of measurements
approximator = ExtendedDMD(sol[:,:], basis)

# Lets look at the eigenvalues
# scatter(eigvals(approximator))

# Get the nonlinear dynamics
dudt_ = dynamics(approximator)
# Solve the estimation problem
prob_ = DiscreteProblem(dudt_, u0, tspan, [])
sol_ = solve(prob_)

# Plot the error
# plot(sol.t, abs.(sol - sol_)')
norm(sol-sol_) # ≈ 4.33e-13

# Get the linear dynamics in koopman space
dψdt = linear_dynamics(approximator)
# Simply calling the EDMD struct transforms into the current basis
ψ_prob = DiscreteProblem(dψdt, approximator(u0), tspan)
ψ = solve(ψ_prob, saveat = sol.t)

# Plot trajectory in edmd basis
# plot(sol.t, ψ')
# plot(sol.t, hcat([approximator(xi) for xi in eachcol(sol)]...)')
norm(ψ - hcat([approximator(xi) for xi in eachcol(sol)]...)) # ≈ 0.0158

# And in observable space
sol_ψ = approximator.output * ψ
# plot(abs.(sol_ψ'- sol[:,:]'))
norm(sol_ψ - sol) # ≈ 0.00664


# Reduce the basis
reduced_basis = reduce_basis(approximator)

# Reiterate for the reduced approximator with few measurements
reduced_approximator = ExtendedDMD(sol[:,1:4], reduced_basis)

dψdt = linear_dynamics(reduced_approximator)
# Simply calling the EDMD struct transforms into the current basis
ψ_prob = DiscreteProblem(dψdt, reduced_approximator(u0), tspan)
ψ = solve(ψ_prob, saveat = sol.t)

# Plot trajectory in edmd basis with much higher accuracy than before
#plot(sol.t, ψ')
#plot!(sol.t, hcat([reduced_approximator(xi) for xi in eachcol(sol)]...)')
norm(ψ - hcat([reduced_approximator(xi) for xi in eachcol(sol)]...)) # ≈ 1.43..



# Update with all other measurements
update!(reduced_approximator, sol[:,8:end-1], sol[:, 9:end], threshold = 1e-7)

dψdt = linear_dynamics(reduced_approximator)
# Simply calling the EDMD struct transforms into the current basis
ψ_prob = DiscreteProblem(dψdt, reduced_approximator(u0), tspan)
ψ = solve(ψ_prob, saveat = sol.t)

# Plot trajectory in edmd basis with much higher accuracy than before
#plot(sol.t, ψ')
#plot!(sol.t, hcat([reduced_approximator(xi) for xi in eachcol(sol)]...)')
norm(ψ - hcat([reduced_approximator(xi) for xi in eachcol(sol)]...)) # ≈ 1.14...

# And in observable space, with lower accuracy since the original states are not in the
# system anymore
sol_ψ = reduced_approximator.output * ψ
#plot(abs.(sol_ψ'- sol[:,:]'))
norm(sol_ψ - sol) # ≈ 1.19
