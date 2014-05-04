using MCMCsim
using Distributions

## Data
lsat = (String => Any)[
  "culm" => [3, 9, 11, 22, 23, 24, 27, 31, 32, 40, 40, 56, 56, 59, 61, 76, 86,
             115, 129, 210, 213, 241, 256, 336, 352, 408, 429, 602, 613, 674,
             702, 1000],
  "response" => reshape(
    [0, 0, 0, 0, 0,
     0, 0, 0, 0, 1,
     0, 0, 0, 1, 0,
     0, 0, 0, 1, 1,
     0, 0, 1, 0, 0,
     0, 0, 1, 0, 1,
     0, 0, 1, 1, 0,
     0, 0, 1, 1, 1,
     0, 1, 0, 0, 0,
     0, 1, 0, 0, 1,
     0, 1, 0, 1, 0,
     0, 1, 0, 1, 1,
     0, 1, 1, 0, 0,
     0, 1, 1, 0, 1,
     0, 1, 1, 1, 0,
     0, 1, 1, 1, 1,
     1, 0, 0, 0, 0,
     1, 0, 0, 0, 1,
     1, 0, 0, 1, 0,
     1, 0, 0, 1, 1,
     1, 0, 1, 0, 0,
     1, 0, 1, 0, 1,
     1, 0, 1, 1, 0,
     1, 0, 1, 1, 1,
     1, 1, 0, 0, 0,
     1, 1, 0, 0, 1,
     1, 1, 0, 1, 0,
     1, 1, 0, 1, 1,
     1, 1, 1, 0, 0,
     1, 1, 1, 0, 1,
     1, 1, 1, 1, 0,
     1, 1, 1, 1, 1], 5, 32)',
  "N" => 1000,
  "R" => 32,
  "T" => 5
]
n = [lsat["culm"][1], diff(lsat["culm"])]
idx = mapreduce(i -> fill(i, n[i]), vcat, 1:length(n))
lsat["r"] = lsat["response"][idx,:]


## Model Specification

model = MCMCModel(

  r = MCMCStochastic(2,
    @modelexpr(beta, theta, alpha, N, T,
      Distribution[
        begin
          p = invlogit(beta * theta[i] - alpha[j])
          Bernoulli(p)
        end
        for i in 1:N, j in 1:T
      ]
    ),
    false
  ),

  theta = MCMCStochastic(1,
    @modelexpr(N,
      IsoNormal(N, 1)
    ),
    false
  ),

  alpha = MCMCStochastic(1,
    @modelexpr(T,
      IsoNormal(T, 1e4)
    )
  ),

  beta = MCMCStochastic(
    :(Uniform(0, 1000))
  )

)


## Initial Values
inits = [
  ["r" => lsat["r"], "alpha" => zeros(lsat["T"]), "beta" => 1,
   "theta" => zeros(lsat["N"])],
  ["r" => lsat["r"], "alpha" => ones(lsat["T"]), "beta" => 2,
   "theta" => zeros(lsat["N"])]
]


## Sampling Scheme
scheme = [SamplerAMWG(["alpha", "beta"], 0.1 * ones(lsat["T"] + 1)),
          SamplerAMM(["theta"], 0.1 * eye(lsat["N"]))]
setsamplers!(model, scheme)


## MCMC Simulations
sim = mcmc(model, lsat, inits, 10000, burnin=2500, thin=2, chains=2)
describe(sim)