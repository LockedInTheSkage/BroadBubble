# Broadening the Bubble

This model is the basis of the paper

**Broadening the Bubble: Technological Countermeasures to Isolation in an Agent-based Simulation of Social Media**

by _Aksel Saugestad, Skage Klingstedt Reistad, Vira Antonova, Ovidiu Victor Tătar, Md. Anwarul Hasan_
([Paper](https://github.com/LockedInTheSkage/BroadBubble/releases/download/1.0/BroadBubble.pdf), [Repository](https://github.com/LockedInTheSkage/BroadBubble), [Web Version](http://netlogoweb.org/web?https://raw.githubusercontent.com/LockedInTheSkage/BroadBubble/master/TripleFilterBubble_Web.nlogo))

It is itsself an extension of the model provided by and discussed in the paper

**The triple filter bubble: Using agent-based modeling to test a meta-theoretical framework for the emergence of filter bubbles and echo chambers**

by _Daniel Geschke, Jan Lorenz, Peter Holtz_
([Paper](https://doi.org/10.1111/bjso.12286), [Repository](https://github.com/janlorenz/TripleFilterBubble), [Web Version](http://netlogoweb.org/web?https://raw.githubusercontent.com/janlorenz/TripleFilterBubble/master/TripleFilterBubble_Web.nlogo))

We recorded results from our simulation manually, but transferred them into a machine-readable format.
The file documenting our simulation results can be found as `SimulationResults.json`.

Some aspects of our extensions are explained in our research paper mentioned above.

## Interactive demonstration

A simplified version of the model (`TripleFilterBubble_Web.nlogo`) also runs in [NetLogoWeb in the browser](http://netlogoweb.org/web?https://raw.githubusercontent.com/LockedInTheSkage/BroadBubble/master/TripleFilterBubble_Web.nlogo). As NetLogoWeb is much slower, many features have been disabled, and the number of simulated agents has been reduced by default. We recommend checking out the web version for an overview of the simulation and its parameters.
However, any research and further experimentation should be done with the regular version, as it is much more performant and feature-rich.

## Reproduce simulation runs

Our simulations were run using [NetLogo 6.3.0](https://ccl.northwestern.edu/netlogo/) and the full NetLogo model (`TripleFilterBubble.nlogo`).

We left the 12 scenarios from the original model intact, and added our own scenarios.
To run a scenario, press the corresponding button, then press `go`.
The simulation will run until the `pause-entropy` (`4.25` by default) is reached.
Here you can take note of different metrics, and continue the simulation afterwards by pressing `go` again.

Like Geschke et al. we ran our simulations for 10.000 timesteps so the system could stabilize. This takes a while! To run the simulations faster, as much of the visuals as possible should be disabled. Hint: Many scenarios converge much earlier, so running until step 10.000 is not always necessary.

## Build your research starting from this model

Quoting from Geschke et al.:
> We appreciate work building on the model. We are open to requests to collaborate on the further exploration and validation of the model as well as for new theory-driven models departing from the existing model. To that end, this repository can (but need not) be used.

This extends to our adapted work as well.
