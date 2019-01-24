var documenterSearchIndex = {"docs": [

{
    "location": "#",
    "page": "Readme",
    "title": "Readme",
    "category": "page",
    "text": ""
},

{
    "location": "#DiffEqBiological.jl-1",
    "page": "Readme",
    "title": "DiffEqBiological.jl",
    "category": "section",
    "text": "(Image: Join the chat at https://gitter.im/JuliaDiffEq/Lobby) (Image: Build Status) (Image: Build status) (Image: Coverage Status) (Image: codecov.io)Full documentation is in the DifferentialEquations.jl models documentation"
},

{
    "location": "#The-Reaction-DSL-1",
    "page": "Readme",
    "title": "The Reaction DSL",
    "category": "section",
    "text": "The @reaction_network DSL allows you to define reaction networks in a more scientific format. Its input is a set of chemical reactions and from them it generates a reaction network object which can be used as input to ODEProblem, SDEProblem and JumpProblem constructors.The basic syntax isrn = @reaction_network rType begin\n  2.0, X + Y --> XY               \n  1.0, XY --> Z            \nendwhere each line corresponds to a chemical reaction. The input rType designates the type of this instance (all instances will inherit from the abstract type AbstractReactionNetwork).The DSL can handle several types of arrows, in both backwards and forward direction. If a bi-directional arrow is used two reaction rates must be designated. These two reaction networks are identicalrn1 = @reaction_network rType begin\n  2.0, X + Y → XY               \n  1.0, XY > Z       \n  1.0, X + Y ← XY               \n  0.5, XY < Z           \nend\nrn1 = @reaction_network rType begin\n  (2.0,1.0), X + Y ↔ XY               \n  (1.0, 0.5), XY ⟷ Z       \nendThe empty set can be used for production or degradation and is declared using either 0 or ∅. Integers denote the number of each reactant partaking in the reaction.rn1 = @reaction_network rType begin\n  2.0, 2X --> 0        \n  2.0, ∅ --> X  \nendMultiple reactions can be declared in a single linern = @reaction_network rType begin\n  2.0, (X,Y) --> 0                   #Identical to reactions [2.0, X --> 0] and [2.0, Y --> 0]\n  (2.0, 1.0), (X,Y) --> 0            #Identical to reactions [2.0, X --> 0] and [1.0, X --> 0]\n  2.0, (X1,Y1) --> (X2,Y2)           #Identical to reactions [2.0, X1 --> X2] and [2.0, Y1 --> Y2]\n  (2.0,1.0), X + Y ↔ XY              #Identical to reactions [2.0, X + Y --> XY] and [1.0, XY --> X + Y].\n  ((2.0,1.0),(1.0,2.0)), (X,Y) ↔ 0   #Identical to reactions [(2.0,1.0), X ↔ 0] and [(1.0,2.0), Y ↔ 0].\nend\n  ```\nParameters can be added to the network by declaring them after the reaction network. Parameters can only exist in the reaction rate and not as a part of the reaction.julia rn = @reaction_network rType begin     (kB, kD), X + Y ↔ XY end kB, kD p = [2.0, 1.0]The parameter set `p` must be passed to the problem constructor. The parameter values can be changed after the reaction network is defined.\n\nThe reaction rate do not need to be constant, but maybe depend on the concentration of the reactants.julia rn = @reaction_network rType begin     (1.0,2XY), X + Y ↔ XY endThe hill function `hill(x,v,K,n) = v*(x^n)/(x^n + K^n)` can be used, as well as the michaelis menten function (the hill function with `n = 1`).julia rn = @reaction_network rType begin     (1.0,hill(XY,1.5,2.0,2)), X + Y ↔ XY endBy using the `@reaction_func` macro it is possible to define your own functions, which may then be used when creating new reaction networks.julia @reactionfunc hill2(x, v, k) = v*x^2/(k^2+x^2)     @reactionnetwork macro can see. rn = @reaction_network rType begin   (1.0,hill2(XY,1.5,2.0)), X + Y ↔ XY end\nReaction rates are automatically adjusted according mass kinetics, including taking special account of higher order terms like `2X -->`. This can be disabled using any non-filled arrow (`⇐, ⟽, ⇒, ⟾, ⇔, ⟺`), in which case the reaction rate will be exactly as input. E.g the two reactions in\nrn = @reaction_network rType begin\n    2.0, X + Y --> XY\n    2.0*X*Y X + Y ⟾ XY\nend\nwill both have reaction rate equal to 2[X][Y].\n\nOnce a reaction network has been created it can be passed as input to either one of the `ODEProblem`, `SDEProblem` or `JumpProblem` constructors.julia   probODE = ODEProblem(rn, args...; kwargs...)         probSDE = SDEProblem(rn, args...; kwargs...)   probJump = JumpProblem(prob,aggregator::Direct,rn)the output problems may then be used as normal input to the solvers of the `DifferentialEquations` package.\n\nThe noise used by the SDEProblem will correspond to the Chemical Langevin Equations. However it is possible to scale the amount of noise be declaring a noise parameter. This will be done after declaring the type but before the network.julia rn = @reaction_network \\eta begin     2.0, X + Y ↔ XY end p = [0.5]The noise term is then added as an additional parameter to the network (by default the last parameter in the parameter array, unless also declared after the reaction network among the other parameters). By reducing (or increasing) the noise term the amount stochastic fluctuations in the system can be reduced (or increased).\n\nIt is possible to access expressions corresponding to the functions determining the deterministic and stochastic development of the network using.julia   fexpr = rn.ffunc   gexpr = rn.gfunc ``` This can e.g. be used to generate LaTeX code corresponding to the system."
},

{
    "location": "autodocs/#",
    "page": "Docstrings",
    "title": "Docstrings",
    "category": "page",
    "text": "Package doesn\'t contain Documenter docs.Docs automatically generated by juliadocs.orgModules = [DiffEqBiological]\nOrder = [:type, :function]"
},

]}
