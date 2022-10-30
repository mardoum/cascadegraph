# CascadeGraph
CascadeGraph is an object-oriented framework for building and running multi-stage neuroscience models in a computation graph. 

![banner](https://i.imgur.com/wBCHB6W.png)

### Introduction

Many models in neuroscience can be divided into multiple distinct stages connected with some structure. Model structure may correspond to biological structure of neural circuits, or it may be a matter of convenience to partition a complex model into simpler sub-units that can be developed and tested more efficiently.

In computer science, a structure like this is called a computation graph. This is a type of graph, meaning it is a set of nodes (vertices) with some connections (edges) between them. In a computation graph, each node represents some computation while edges define the flow of data, directing the nodes' inputs and outputs.

**CascadeGraph is a framework for flexible modeling using computation graphs. It places object-oriented programming at the center of model development: each node in the graph is an instance of a particular class which defines the operations it performs. Each node stores a list of connected upstream nodes, as well as any parameters needed to process inputs. To run a model, a graph traversal algorithm schedules computations in the order defined by the structure of the graph.** Each node waits for all the necessary inputs from upstream nodes before executing.

Nodes can execute simple operations, such as summing all inputs, or more complex operations, like filtering a signal. There is no limit to node complexity, so nodes can even contain entire sub-models like a system of differential equations or a deep neural network.

### Why use it?

CascadeGraph achieves flexibility and modularity in model building with object-oriented design. The key advantages are:
* The code that defines model components is separated from the code that defines model structure. This means it is possible to add, remove, or rearrange nodes and edges without modifying the code that defines the components and their computation.
* Different nodes or entire models can be handled with a common interface. Comparing the outputs of multiple different models is made easy: there's no need to use conditional logic or wrappers to select the correct parameters and functions for each model at runtime. Instead, each model's parameters are stored in the node instances themselves, and the associated methods are intrinsic to each node class. 
* Code is modular and extensible. To add a new node type, simply write a new node class.

### Requirements

Each model must be a directed acyclic graph (DAG), meaning it must be possible to schedule computations in a fixed order, with later components depending only on earlier components' outputs. There can be no cycles in the graph since cycles create infinite loops in execution.

### Getting started

Add CascadeGraph and its subfolders to your path.
```Matlab
% Replace <path_to_folder> with the actual path to the top level cascadegraph folder
addpath(genpath(<path_to_folder>))
```

For examples and usage, see the demo script `DemoMain.m`, which explains how to use CascadeGraph using simple example models that incorporate just a few nodes. The core class definition files `ModelNode.m`, `ParameterizedNode.m`, and `HyperNode.m` also contain comments that are helpful to read before developing your own models.

### License

This project is licensed under the terms of the MIT license.