# CascadeGraph
CascadeGraph is a package for building computational models using a graph (a set of nodes with edges, or connections, between them), where each node is an object that describes some computation and edges control the flow of data. Model execution is performed as a graph traversal. This object-oriented approach to model building enables flexible assignment of model architecture, reusability of components, and encapsulation of methods and data in each component.

CascadeGraph is designed and tested only for use on models that can be expressed as directed acyclic graphs (DAGs).

The library of node classes currently included in CascadeGraph represent common model components in computational neuroscience, and are specialized for modeling neural circuits. The core classes are general, though, and can be subclassed to extend the node library to support any model that can be expressed as a directed acyclic graph.

### Getting started
To get started, step through the demo script `DemoMain.m`, which explains how to use CascadeGraph to build simple models with just a few nodes. The core class definitions `ModelNode`, `ParameterizedNode`, and `HyperNode` also contain comments that are helpful to read before developing your own models.

For reference, the class inheritance structure of the three core node classes, plus a sampling of others, is schematized here:

![class inheritance image](https://i.imgur.com/A8Ysiux.png)

This project is licensed under the terms of the MIT license.