# processing-projects
## COVID-19 Simulator by Choudry Abdul Rehman
The COVID-19 Simulator is based on [this Washington Post simulation](https://www.washingtonpost.com/graphics/2020/world/corona-simulator/). In its current state, it simulates a scenario in which people are social distancing. *This is not meant as a real simulation of COVID-19 transmission, nor should it be taken as medical advice.*

The simulator is largely built off of the [CircleCollision](https://processing.org/examples/circlecollision.html) example by Ira Greenberg.

There are two primary classes:`Ball` and `Column`.

**`Ball`** represents a person in the simulation. It is mostly unchanged from the CircleCollision example, but with the addition of a few instance variables that hold the individual's state (e.g. whether or not they are social distancing, their infected/uninfected/recovered state). 

**`Column`** represents a column of the graph that is above the simulation. It calculates the sizes of the rectangles that make up a column based on the ratio between each of the "types" of people (infected, uninfected, recovered). 

The Improvements that I plan to make to this simulation:

* Logic:
  * The Simulator takes into account the level of measures that are taken to control the spread of disease (Social distancing and Quarantine)
  * Additional paramaters that show whether people are wearing masks (would change the probability of people getting infected on contact)
  * Additional variables including number of sick people in the start.
  * Level of health care facilities available

* User interface:
  * Gives users more control of the simulation like they can restart it and change certain parameters.
  