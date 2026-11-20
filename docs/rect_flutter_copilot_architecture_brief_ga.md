# Rect.js → Flutter: Architecture Investigation Brief — COM + Geometric Algebra

> **Purpose:** Give GitHub Copilot a reliable project context and a
> structured investigation plan. This document is a starting brief, not
> an instruction to implement the entire roadmap in one pass.

## 1. Project identity

-   **Project:** `vekt_flutter`
-   **Repository:** https://github.com/gaucho96/vekt_flutter
-   **Branch snapshot referenced:** `develop`
-   **Original project:** https://github.com/projektorius96/Rect.js
-   **Related CLI project:** https://github.com/projektorius96/cli

The ambition is to evolve a Rect.js-inspired Flutter application into a
modular 2D graphics engine. The direction is increasingly comparable to
a Konva.js-style scene/rendering system, while using Flutter's widget
composition and `Canvas`/`CustomPainter` capabilities.

The project is also a hands-on learning exercise. Explanations and
proposed changes should help the developer understand Dart, Flutter,
rendering, coordinate geometry, **linear algebra and Geometric Algebra
(GA)**, including the mathematical reasoning behind architectural
decisions.

A key updated priority is to make **2D Euclidean Geometric Algebra,
\(\mathcal{G}(2,0)\)** the primary mathematical learning and domain-design
framework for vectors, bivectors, multivectors, rotations, and linear
transformations. Matrix representations are not forbidden, but should not
be the default conceptual starting point or the only proposed solution.

## 2. Non-negotiable design constraints

1.  **MVC as the familiar application-architecture starting point**
    -   Model: intentionally deferred for the current early stage, but
        the design must not prevent introducing it later.
    -   View: Flutter UI and presentation.
    -   Controller: delegates between model and view when introduced.
    -   Do not impose MVVM or a more elaborate architecture without a
        concrete need and an explicit discussion.
2.  **The domain layer must not depend on Flutter.**
    -   Keep domain types and calculations in pure Dart.
    -   Flutter-specific rendering belongs in
        presentation/infrastructure code.
    -   Do not import `package:flutter/...` from the domain layer.
3.  **Functional-programming-first where practical.**
    -   Prefer pure calculations, explicit inputs and outputs, immutable
        values/snapshots, and small composable functions.
    -   Avoid unnecessary mutable shared state and hidden side effects.
    -   Use Dart records, immutable collections or defensive
        unmodifiable views where they provide a real benefit.
    -   Do not force functional abstractions where ordinary Dart is
        clearer.
4.  **No Material or Cupertino design systems.**
    -   Do not introduce `MaterialApp`, Material widgets, Cupertino
        widgets, or their design systems unless explicitly requested.
    -   Flutter's style-neutral foundational widgets are allowed,
        including `WidgetsApp` only if its broader behavior is
        justified; `Directionality`, `Stack`, `CustomPaint`,
        `IgnorePointer`, `Listener`, `GestureDetector`, and similar
        foundational widgets are acceptable.
    -   Supply required ambient infrastructure explicitly where needed.
        For example, directional layout needs a `Directionality`
        ancestor or an explicitly non-directional alignment/text
        direction.
5.  **Geometric Algebra is a first-class mathematical direction.**
    -   Start from linearly independent basis vectors and the geometry
        they span; distinguish geometric objects from their coordinate
        representations.
    -   Prioritize 2D Euclidean Geometric Algebra, \(\\mathcal{G}(2,0)\),
        as the initial mathematical setting.
    -   Treat scalars (grade 0), vectors (grade 1), bivectors (grade 2),
        and multivectors (mixed grades) as important concepts.
    -   Teach and investigate the inner product, outer product, and
        geometric product, including their distinct geometric meanings.
    -   Make bivectors and oriented area first-class concepts, not merely
        an incidental determinant calculation.
    -   Prefer basis-vector mappings and outermorphisms when explaining
        general linear transformations; use rotors and the sandwich
        product for rotations.
    -   Distinguish linear transformations from affine transformations:
        translations are not ordinary linear maps on position vectors.
        Investigate affine models and, later if useful, Projective
        Geometric Algebra (PGA) rather than pretending a rotor alone
        represents every transformation.
    -   Do not ban matrices. Explain their relationship to the GA
        formulation and use them as a possible implementation,
        interoperability, or optimization representation when justified.
    -   Keep the mathematical domain pure Dart and independent of Flutter.
6.  **Performance is a priority.**
    -   Prefer avoiding unnecessary geometry generation and Canvas draw
        calls.
    -   Keep performance claims precise: fewer draw calls are not
        automatically an equivalent percentage improvement in frame
        rate.
    -   Avoid premature complexity. Optimize based on rendering
        responsibilities and likely bottlenecks.
    -   Testing is intentionally deferred until the planned
        implementation work is substantially complete, but do not make
        claims that code is tested when it is not.

## 3. Current repository snapshot: verified baseline

Repository tree: https://github.com/gaucho96/vekt_flutter/tree/develop

Project structure:

``` text
lib/
├── main.dart
├── domain/
│   └── grid.dart
└── views/
    ├── stage.dart
    └── layers/
        └── grid/
            ├── grid.config.dart
            ├── grid_layer.dart
            └── grid_renderer.dart
```

### 3.1 Entry point and stage composition

`lib/main.dart` currently launches `Stage`:

``` dart
void main() {
  runApp(const Stage());
}
```

`lib/views/stage.dart` currently uses a Flutter `Stack` and a
`CustomPaint` whose painter is `Grid`. It explicitly sets:

``` dart
textDirection: TextDirection.ltr,
fit: StackFit.expand,
```

The explicit `textDirection` matters because `Stack`'s default
directional alignment otherwise requires a `Directionality` ancestor.
This is compatible with the project's design-system-neutral constraint.

The current stage is an initial composition point, not yet a complete
plugin framework.

### 3.2 Grid domain

`lib/domain/grid.dart` currently defines record types:

``` dart
typedef GridConfig = ({
  double spacing,
});

typedef ViewportSize = ({
  double width,
  double height,
});

typedef GridGeometry = ({
  List<double> verticalLines,
  List<double> horizontalLines,
});
```

It also provides `calculateGridGeometry(...)`, which calculates visible
vertical and horizontal grid-line positions from grid configuration and
viewport dimensions.

The line-position helper uses integer bounds:

``` dart
final minIndex = (-center / spacing).ceil();
final maxIndex = ((extent - center) / spacing).floor();
```

It returns an unmodifiable list of positions. The calculation validates
that spacing is finite and greater than zero.

This is a useful existing example of a pure domain calculation separated
from Canvas drawing.

### 3.3 Grid presentation and renderer

-   `grid.config.dart` contains Flutter-specific colours and `Paint`
    configuration.
-   `grid_layer.dart` currently defines `Grid extends CustomPainter`,
    accepts `GridConfig`, `showGrid`, and `showXY`, paints the
    background, and delegates grid/axis drawing.
-   `grid_renderer.dart` contains Canvas drawing functions such as
    `drawGrid(...)` and `drawXY(...)`.

Important investigation item: the current `Grid.shouldRepaint`
implementation returns `false`. Review whether that is correct when
painter configuration or visibility can change. Do not silently assume
it is correct or change it without explaining the repaint contract.

Also inspect whether the current top-level `Paint` objects are safe to
share as mutable objects, and whether configuration should instead be
represented as immutable values from which painter-owned `Paint`
instances are constructed. Recommend the simplest correct approach.

### 3.4 Existing grid optimization

The earlier grid implementation used symmetric negative-to-positive loop
bounds and could issue drawing calls for lines outside the visible
viewport.

The current domain calculation derives the minimum and maximum integer
grid indices that intersect the viewport. The README documents an
illustrative comparison for a 1200 × 800 logical-pixel viewport with
40-pixel spacing:

  Measure                   Initial   Optimized
  ----------------------- --------- -----------
  Vertical iterations            61          31
  Horizontal iterations          41          21
  Total line draw calls         102          52

This is approximately 49% fewer grid-line drawing operations in that
example. It is **not** a measured 49% frame-rate or rendering-time
improvement.

## 4. Architectural direction: composable rendering layers

The agreed direction is to treat visual features as independently
composable Flutter widgets/layers wherever that makes sense.

A possible future composition:

``` text
Stage (Flutter Stack)
├── BackgroundLayer
│   └── GridLayer
├── ContentLayer
│   └── ComLayer
└── OverlayLayer
    ├── SelectionLayer
    └── GuidesLayer
```

Potential future layers include:

-   Grid/background
-   Main scene content
-   Selection outlines
-   Alignment guides
-   Interaction overlays, handles, and feedback

### Layer principles

-   Child order in `Stack` determines visual paint order: earlier
    children are behind later children.
-   `Stack` is a Flutter presentation/composition mechanism.
-   A layer may own one or more `CustomPainter`s, but a Flutter `Stack`
    child is not equivalent to a separate HTML `<canvas>` element.
-   `Stack` does not automatically create an independent rasterization
    boundary for every child.
-   Use `IgnorePointer`, `AbsorbPointer`, or interactive widgets
    according to each layer's pointer/hit-test responsibility.
-   Consider `RepaintBoundary` only where independent repaint lifetimes
    justify it; do not add one to every layer by default.
-   Do not build a dynamic plugin-registration/lifecycle framework
    prematurely. Ordinary composable widgets are sufficient initially.

## 5. Canvas Object Model (COM): emerging first-class architecture

A parallel design discussion introduced a Canvas Object Model (COM).
This should now be treated as a first-class architectural milestone, not
merely an implementation detail of shape painting.

The key conceptual model:

``` text
ComNode
├── ComGroup
│   ├── ComNode / shape
│   ├── ComNode / shape
│   └── ComGroup
│       ├── ComNode / shape
│       └── ComNode / shape
└── other node implementations
```

The central idea is that `ComGroup` extends or implements the common
`ComNode` abstraction, so a group can itself be nested inside another
group. This produces a recursive scene graph.

**Do not treat the sketch above as an already implemented API.** The COM
types are an emerging design direction and must be investigated and
designed before implementation.

### 5.1 Group-first local coordinates

The most important COM principle is that nodes should use **local
coordinates relative to their owning parent/group**, rather than storing
every shape position directly in application-window coordinates.

Conceptual hierarchy:

``` text
Stage / viewport coordinate space
└── ComGroup A (local transform A)
    └── ComGroup B (local transform B)
        ├── ComShape A (local transform/position)
        └── ComShape B (local transform/position)
```

A child position is interpreted in its parent's coordinate space.
A node's final/world geometry is derived from its local geometric data
and the transformations of its ancestors.

**Do not make a matrix product the default conceptual explanation.**
Investigate the same problem using a GA-oriented vocabulary:

- A coordinate frame is described by a chosen set of linearly independent
  basis vectors (and, where relevant, an origin).
- A vector is a geometric object expressed as a linear combination of
  that frame's basis vectors.
- A child group's local frame is related to its parent frame by a
  transformation.
- Linear maps can be specified by their action on basis vectors and
  extended to outer products using an **outermorphism**.
- Rotations can be represented by rotors and applied using the sandwich
  product.
- Translation requires affine handling (or a deliberately chosen
  projective/other model); do not misclassify it as an ordinary linear
  transformation.

The earlier matrix product shown in prior discussions is only one possible coordinate representation; it is not the project's preferred mathematical starting point. The exact GA formulation, representation, composition order, and API must be researched
and documented. Matrices may be introduced as an equivalent or useful
computational representation, but explain what they encode and how they
relate to the GA formulation. Never assume that a matrix-free formulation
is automatically faster or simpler in code.

This approach should support:

-   Nested groups
-   Group translation and transformation
-   Reusable subtrees
-   Predictable local positioning
-   Converting between local, world, and viewport coordinates
-   Future hit testing and selection

### 5.2 Keep COM separate from Flutter widgets

Do not create a Flutter `Stack` or widget subtree for every `ComGroup`.

These are distinct hierarchies:

-   Flutter widget/layer hierarchy: presentation and rendering
    composition.
-   COM hierarchy: domain-level scene graph and object relationships.

A content rendering layer can traverse the COM tree and issue Canvas
operations. The domain scene graph should not depend on Flutter widgets
or `Canvas`.

## 6. Proposed roadmap

This roadmap is a working plan. Reconcile it with the actual source tree
and existing README before changing files. Some original chunk numbers
are retained for continuity, while COM milestones are added explicitly.

### Phase I --- Rendering foundation

  -----------------------------------------------------------------------
  Chunk                   Topic                   Current understanding
  ----------------------- ----------------------- -----------------------
  01                      Source analysis and     Initial analysis
                          feature contract        completed

  02                      Basic Flutter           Initial foundation
                          architecture            established

  07                      `CustomPainter`         Grid painter
                          foundations             implemented

  08                      Grid geometry, renderer Implemented in current
                          separation, and         form; layer composition
                          modularization          can evolve
  -----------------------------------------------------------------------

### Phase II --- Linear algebra and Geometric Algebra foundations

This phase deliberately precedes implementation of a general COM
transformation system. Learn the mathematical objects and operations
before committing to their Dart representation.

| Chunk | Topic | Intended outcome |
|---|---|---|
| 03 | Immutable data modelling | Understand Dart records, immutable value types, and pure domain contracts |
| GA-01 | Linear algebra foundations | Understand vector spaces, linear independence, bases, coordinates, and linear combinations |
| GA-02 | 2D Euclidean Geometric Algebra | Understand \(\\mathcal{G}(2,0)\), the geometric product, inner product, outer product, grades, and multivectors |
| GA-03 | Bivectors and oriented geometry | Understand the 2D pseudoscalar, oriented area, wedge products, and orientation reversal |
| GA-04 | Rotors and rotations | Understand reversion, bivector exponentials, rotors, sandwich products, and rotation composition |
| GA-05 | Linear maps and outermorphisms | Transform basis vectors and extend linear maps consistently to vectors and bivectors |
| GA-06 | Affine geometry | Distinguish linear maps from translations; study affine frames and local/world coordinate relationships |
| 04–06 | Geometry and computational foundations | Apply the mathematics to coordinate frames, geometric primitives, paths, and numerical representation |

### Phase III --- Canvas Object Model (COM), designed around GA

| Milestone | Topic | Intended outcome |
|---|---|---|
| COM-01 | `ComNode` foundation | Define the shared pure-Dart node contract and identity/ownership decisions |
| COM-02 | `ComGroup` | Define a group as a node that can contain child nodes and establish a local frame |
| COM-03 | Parent-child relationships | Define safe tree construction, ownership, immutable snapshots, and traversal |
| COM-04 | Local coordinate frames | Express child geometry relative to its parent frame, based on linearly independent basis vectors |
| COM-05 | Transformation composition | Compose ancestor/local geometric transformations; compare GA and matrix representations explicitly |
| COM-06 | Shape nodes | Introduce concrete drawable domain nodes with local geometric data |
| COM-07 | Scene traversal | Traverse the COM hierarchy and derive world-space geometry for rendering and future operations |

### Phase IV --- Rendering layers and interaction

  -----------------------------------------------------------------------
  Milestone               Topic                   Intended outcome
  ----------------------- ----------------------- -----------------------
  09                      Shape rendering         Render COM shapes
                                                  through dedicated
                                                  Flutter presentation
                                                  code

  10                      Additional drawing      Expand
                          primitives              geometry/rendering
                                                  capabilities

  11                      Controllers and         Add pointer handling,
                          interaction             selection, and
                                                  controller delegation

  12                      Integration and         Review rendering work,
                          performance             repaint behavior, and
                                                  bottlenecks
  -----------------------------------------------------------------------

### Phase V --- Future capabilities

These are possibilities, not immediate commitments:

-   Scene graph serialization/deserialization
-   Dynamic layer configuration or plugin lifecycle, if needed
-   Hit testing and selection
-   Group manipulation
-   Visibility, opacity, clipping, and inheritance semantics
-   More advanced rendering optimizations

## 7. Suggested investigation tasks for GitHub Copilot

Work incrementally. Start by inspecting the repository and reporting
findings; do not immediately rewrite the project.

### Investigation A --- Validate the current baseline

1.  Inspect the current `develop` branch source files and README.
2.  Confirm which statements in this brief still match the code.
3.  Identify inconsistencies, dead code, questionable APIs, and missing
    pieces.
4.  Review `Grid.shouldRepaint`, shared `Paint` instances, grid
    configuration, and `Stack` composition.
5.  Report findings with exact file paths and concise reasoning.
6.  Do not change code during this first investigation.

### Investigation B --- Design the COM domain model

Propose a minimal, pure-Dart COM design.

Address these questions explicitly:

-   Should `ComNode` be an `abstract class`, `abstract interface class`,
    `sealed class`, or another Dart construct? Explain the trade-offs.
-   Should `ComGroup` extend `ComNode` or implement an interface? Align
    with the desired substitutability and shared behavior.
-   How should node identity be represented?
-   How should parent ownership be represented, if at all?
-   How should child collections be stored and exposed immutably?
-   How should mutations or edits be represented while preserving
    immutable snapshots?
-   How should a group with no children behave?
-   How should traversal be expressed using pure functions/iterables?
-   How should local transforms be represented without Flutter
    dependencies?
-   What is the smallest useful initial model that does not prematurely
    implement a full graphics framework?

Do not implement until the proposed model and trade-offs have been
explained.

### Investigation C --- GA-first coordinate and transformation design

Research and propose a coordinate/transformation model whose **primary
mathematical explanation is Geometric Algebra**, not a matrix-only
pipeline.

#### C1. Mathematical setting and basis

- Start with 2D Euclidean Geometric Algebra, \\(\\mathcal{G}(2,0)\\).
- Define the vector space and a pair of linearly independent basis
  vectors.
- Explain the difference between a geometric vector and its coordinate
  coefficients in a selected basis.
- Explain orthonormal and non-orthonormal bases, and identify which
  assumptions the initial engine will make.
- Define the metric assumptions explicitly.

#### C2. Grades and products

- Explain scalars, vectors, bivectors, and multivectors.
- Define the inner product, outer product, and geometric product, and
  explain what geometric information each carries.
- Establish the 2D unit pseudoscalar/bivector and its orientation.
- Explain how the outer product of two vectors represents an oriented
  parallelogram area.
- Show how a change of basis or linear map changes vectors and bivectors.

#### C3. Linear transformations and outermorphisms

- Prefer defining a linear map by its action on a basis, then extending
  it linearly to vectors.
- Investigate the induced outermorphism on bivectors and other outer
  products:
  \\(f(a \\wedge b)=f(a)\\wedge f(b)\\).
- Explain area scaling and orientation changes through the transformed
  bivector.
- Explain where matrices fit: as coordinate representations of linear
  maps in a chosen basis, not as the only conceptual model.
- Compare GA-first and matrix representations for correctness,
  implementation complexity, numerical behavior, and performance.
- Do not claim that avoiding matrices is inherently faster.

#### C4. Rotations

- Explain the 2D pseudoscalar and its square under the chosen Euclidean
  metric.
- Derive the rotor using the exponential of a bivector.
- Explain reverse, rotor construction, and the sandwich action
  \\(v' = R v \\widetilde{R}\\).
- Distinguish rotations represented by rotors from arbitrary linear
  transformations represented by general linear maps/outermorphisms.

#### C5. Affine transformations and translations

- Explicitly distinguish linear transformations (which preserve the
  origin) from affine transformations (which may translate it).
- Do not claim that an ordinary rotor or ordinary linear outermorphism
  alone implements translation of position points.
- Compare a simple affine-frame representation with Projective
  Geometric Algebra (PGA) as a possible later direction.
- Do not introduce PGA prematurely; explain what concrete capabilities
  would justify it.

#### C6. Coordinate spaces and COM nesting

- Local coordinates
- Parent-frame coordinates
- World coordinates
- Viewport coordinates
- Stage/canvas coordinates
- Forward and inverse coordinate conversion
- How a nested `ComGroup` establishes a local frame
- How a node's local geometry is mapped through its ancestors
- How pointer positions can eventually be converted from viewport space
  into a node's local space

The group-first principle is mandatory: children describe their geometry
in the coordinate frame of their owning group, not directly in
application-window coordinates.

#### C7. Implementation boundary

- Keep all GA and coordinate-frame mathematics in pure Dart.
- Propose small, immutable, testable value representations and pure
  operations.
- Explain the trade-offs between Dart records, value classes, and
  specialized types for vectors, bivectors, rotors, and multivectors.
- Keep Flutter `Offset`, `Size`, `Canvas`, and `Matrix4` out of the domain
  API. Convert at the presentation/rendering boundary.
- Matrix types may be used in a rendering adapter or optimized backend
  if justified, without making them the domain's primary conceptual API.

Do not implement until the mathematical conventions, types, and
trade-offs have been explained with worked 2D examples.

### Investigation D --- Rendering integration

Propose how a Flutter rendering layer should consume the COM tree:

-   Where traversal belongs
-   How domain geometry is translated into Canvas calls
-   How group transforms are applied during traversal
-   How painter configuration and repaint decisions work
-   How rendering layers remain independent
-   How pointer events and hit testing can later map back to COM nodes

Do not create one Flutter widget per COM node by default. Explain when a
widget-per-node design would or would not be justified.

The renderer must consume the domain's GA-aware geometry without making
the domain depend on Flutter. Explain where any conversion to Flutter
`Offset`, `Path`, `Canvas`, or matrix APIs occurs. Do not silently replace
the GA domain model with a matrix-only renderer contract.

## 8. Mathematics and learning expectations

The developer wants to learn both programming and mathematics by building
the application. Treat mathematical understanding as a deliverable, not
as incidental commentary.

For each substantial mathematical feature:

1. State the geometric problem in plain language.
2. Introduce the relevant definitions and assumptions.
3. Derive the formula step by step, including what each symbol means.
4. Work through a concrete 2D numerical or symbolic example.
5. Explain how the result maps to a pure-Dart representation.
6. Explain how the result eventually affects COM or Canvas rendering.
7. Compare alternative formulations where useful, without presenting
   matrices as the only valid language.

Use correct terminology carefully. In particular:

- A bivector in 2D represents an oriented area element.
- The wedge product is not the same operation as the inner product.
- The geometric product contains both inner- and outer-product grade
  contributions (under the chosen convention).
- A rotor is appropriate for rotations, not a universal representation
  of every possible linear or affine transformation.
- An outermorphism extends a linear map to outer products.
- Translation is affine, not an ordinary linear transformation of
  position vectors.
- Coordinate coefficients depend on the chosen basis; the geometric
  object and its coordinate representation are not identical concepts.

Do not overload the first implementation with a general-purpose GA
framework. Begin with the smallest useful 2D subset and expand only when
a concrete graphics or learning requirement calls for it.

## 9. Collaboration and response expectations

The developer is learning Dart and Flutter while building the project.
Therefore:

-   Explain unfamiliar Dart syntax and Flutter behavior instead of
    merely supplying code.
-   Explain why a design is appropriate, not just what to paste.
-   Prefer small, coherent implementation steps.
-   Show file paths and clarify which files are new or modified.
-   Preserve the existing MVC preference and pure-Dart domain boundary.
-   Avoid unnecessary architecture jargon and speculative abstractions.
-   Clearly distinguish existing implementation, proposed design, and
    optional future ideas.
-   Do not claim that an implementation exists until it is visible in
    the repository.
-   Do not silently change project direction or introduce
    Material/Cupertino dependencies.
-   Keep performance reasoning grounded and distinguish operation-count
    reductions from measured runtime gains.

## 10. Immediate next step

**Begin with Investigation A: validate the current `develop` branch
against this brief.** Then review Investigation C and identify any
matrix-centric assumptions in the existing proposal that should be
reframed around the GA-first direction.

Return:

1.  A concise verified snapshot of the current architecture.
2.  Any inaccuracies or outdated statements in this document.
3.  A list of architectural risks or decisions that need attention.
4.  A recommended sequence for Chunk 03, GA-01 through GA-03, and COM-01, explaining which mathematical foundations should precede each COM decision.

Do not implement code yet. The goal is to establish a shared, accurate
understanding before the next implementation session.
