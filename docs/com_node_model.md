# Minimal Canvas Object Model

This first COM step defines only a shared node identity, a nestable group, and
a way to traverse the tree. It does not define shapes, transforms, coordinate
systems, parent pointers, or rendering behavior.

## Node identity and Dart types

`ComNode` is an `abstract interface class` with one required getter, `id`.
The interface gives different node classes a common type without requiring
them to inherit base-class state or behavior. Its `String` identifier is
provided by the caller; this minimal contract does not generate identifiers or
enforce uniqueness.

The domain already uses named Records for small data bundles such as
`GridConfig` and `ViewportSize` in `lib/domain/grid.dart`. Records are concise
and structurally typed, which suits values whose purpose is to group fields.
A COM node instead needs a named, nominal contract that groups can implement
alongside future node kinds. A class/interface makes that shared identity
contract explicit; a Record would only bundle fields and would not establish
the same substitutable node type.

## Groups and immutable snapshots

`ComGroup` implements `ComNode` and stores children in their supplied order.
It is a `final class`: other node kinds can implement `ComNode`, but cannot
subclass `ComGroup` and weaken its collection invariant.
The constructor accepts an `Iterable<ComNode>` and creates a new list with
`List.unmodifiable`. This both prevents callers from changing the group's
child list through the exposed `children` property and prevents later changes
to the input collection from changing the group.

This is a shallow snapshot: child node objects are referenced, not recursively
copied or made immutable by the group. `copyWith` creates a new group; it
reuses the existing id or child references when those arguments are omitted,
and the constructor takes a fresh child-list snapshot. Its named optional
parameters let a caller replace either field while leaving the other
unchanged. Empty groups are valid. No parent reference or mutable add/remove
API is included.

## Traversal

`traverseComPreOrder` is a lazy synchronous generator. It yields the root
before descending through its children, so a group appears before its
descendants. In this initial model, a `ComGroup` is traversable and another
`ComNode` implementation is treated as a leaf. The traversal does not mutate
the nodes.

## Flutter boundary

COM belongs to the pure-Dart domain and imports no Flutter types. A `ComGroup`
is not a Flutter widget and does not correspond to a widget subtree. The
current `Stage` uses a Flutter `Stack` for presentation composition; a future
content renderer can traverse COM and issue drawing operations through
`CustomPainter`/`Canvas` in presentation code. That boundary is why this
contract contains no `Widget`, `Offset`, `Size`, or `Canvas`.

No geometric algebra, coordinate-frame, or transform representation is chosen
here. Those decisions can be made separately without putting assumptions into
node identity or group ownership.
