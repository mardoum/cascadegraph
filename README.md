# CascadeGraph
CascadeGraph is a package for building computational models using a graph (a set of nodes with some connections, edges, between them), where each node is an object that describes some computation and edges control the flow of data. By traversing the graph, CascadeGraph executes the computations described at each node. This object-oriented approach to model building enables flexible assignment of model architecture, reusability of components, and encapsulation of methods and data in each component.

#### Notes on generality, limitations:
Currently, CascadeGraph is designed and tested only for use on models that can be expressed as directed acyclic graphs (DAGs). The package could be extended to handle cycles, which would add the capability to incorporate feedback or implement closed-loop simulations.

The core classes of CascadeGraph are general and can be subclassed to create any model that can be expressed as a directed acyclic graph. Many of the particular subclasses in the current package build are classes I use in my work as a computational neuroscientist modeling the function of neural circuits.

### Getting started
To get started, step through `DemoMain.m`. It is also helpful to read core class definitions `ModelNode`, `ParameterizedNode`, and `HyperNode`.

For reference, the class inheritance structure of the node classes is schematized here:

![class inheritance image](https://i.imgur.com/A8Ysiux.png)