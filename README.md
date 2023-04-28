This model is the basis of the paper

**Broadening the Bubble: Technological Countermeasures to Isolation in an Agent-based Simulation of Social Media**

by _Aksel Saugestad, Skage Klingstedt Reistad, Vira Antonova, Ovidiu Victor Tatar, Md. Anwarul Hasan_

It is itsself an extension of the model provided by and discussed in the paper

**The triple filter bubble: Using agent-based modeling to test a meta-theoretical framework for the emergence of filter bubbles and echo chambers**

by _Daniel Geschke, Jan Lorenz, Peter Holtz_

We recorded results from our simulation manually, but transferred them into a machine-readable format.
The file documenting our simulation results can be found as `SimulationResults.json`.

Some aspects of our extensions are explained in our research paper mentioned above.
**All further details described here are from the original paper! We did not update this description.**

# TripleFilterBubble

Providing reproducible simulations and analysis for the paper "The triple filter bubble: Using agent-based modelling to test a meta-theoretical framework for the emergence of filter bubbles and echo chambers" (2018) Daniel Geschke, Jan Lorenz, Peter Holtz

The submitted version is provided in the repository: GeschkeLorenzHoltz2017TripleFilterBubble_Submitted.pdf
(Note, that the simulation results deviate quantitatively from the simulation results produce the NetLogo model, because the model has been rescaled after peer review. The results do not differ qualitatively.)

The link to the published version will be provided here once published.
The accepted version will be provided as a preprint after the embargo period.


## Reproduce simulation runs

Use the NetLogo model (TripleFilterBubble.nlogo).

Simulations should preferable be run in NetLogo 6.0.4. (Download free https://ccl.northwestern.edu/netlogo/).
Run the 12 scenarios using the provided buttons. Run them for 10.000 timesteps (this can take a while!) and compare the results. Hint: For most scenarios the numbers are approached faster and much less than 10.000 timesteps are needed to reproduce the stylized facts.

A simplified version of the model (TripleFilterBubble_Web.nlogo) also runs in NetLogoWeb in the browser. It runs much slower. Therefore, the configuration is by default with lower a numbers of guys and a lower number of friendship links. Further on, the visualization of links is switched off by default. Try this link:
http://netlogoweb.org/web?https://raw.githubusercontent.com/janlorenz/TripleFilterBubble/master/TripleFilterBubble_Web.nlogo


## Build your research starting from this model

We appreciate work building on the model. We are open to requests to collaborate on the further exploration and validation of the model as well as for new theory-driven models departing from the existing model. To that end, this repository can (but need not) be used.
