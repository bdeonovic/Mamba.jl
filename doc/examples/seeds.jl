using MCMCsim
using Distributions

## Data
seeds = (String => Any)[
  "r" => [10, 23, 23, 26, 17, 5, 53, 55, 32, 46, 10, 8, 10, 8, 23, 0, 3, 22, 15,
          32, 3],
  "n" => [39, 62, 81, 51, 39, 6, 74, 72, 51, 79, 13, 16, 30, 28, 45, 4, 12, 41,
          30, 51, 7],
  "x1" => [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
  "x2" => [0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1],
  "N" => 21
]


## Model Specification

model = MCMCModel(

  r = MCMCStochastic(1,
    @modelexpr(alpha0, alpha1, x1, alpha2, x2, alpha12, b, n, N,
      begin
        eta = alpha0 + alpha1 * x1 + alpha2 * x2 + alpha12 * x1 .* x2 + b
        p = 1.0 / (exp(-eta) + 1.0)
        Distribution[Binomial(n[i], p[i]) for i in 1:N]
      end
    ),
    false
  ),

  b = MCMCStochastic(1,
    @modelexpr(N, s2,
      IsoNormal(N, sqrt(s2))
    ),
    false
  ),

  alpha0 = MCMCStochastic(
    :(Normal(0.0, 1.0e6))
  ),

  alpha1 = MCMCStochastic(
    :(Normal(0.0, 1.0e6))
  ),

  alpha2 = MCMCStochastic(
    :(Normal(0.0, 1.0e6))
  ),

  alpha12 = MCMCStochastic(
    :(Normal(0.0, 1.0e6))
  ),

  s2 = MCMCStochastic(
    :(InverseGamma(0.001, 0.001))
  )

)


## Initial Values
inits = [
  ["r" => seeds["r"], "alpha0" => 0, "alpha1" => 0, "alpha2" => 0,
   "alpha12" => 0, "s2" => 0.01, "b" => zeros(seeds["N"])],
  ["r" => seeds["r"], "alpha0" => 0, "alpha1" => 0, "alpha2" => 0,
   "alpha12" => 0, "s2" => 1, "b" => zeros(seeds["N"])]
]


## Sampling Scheme
scheme = [SamplerAMM(["alpha0", "alpha1", "alpha2", "alpha12"], 0.01 * eye(4)),
          SamplerAMWG(["b"], 0.01 * ones(seeds["N"])),
          SamplerSlice(["s2"], [1.0])]
setsamplers!(model, scheme)


## MCMC Simulations
sim = mcmc(model, seeds, inits, 10000, burnin=2500, thin=2, chains=2)
describe(sim)