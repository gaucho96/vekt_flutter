/// The shared identity contract for a node in the Canvas Object Model.
///
/// This domain interface is independent of Flutter. Implementations provide
/// their own behavior while remaining identifiable as COM nodes.
abstract interface class ComNode {
  /// The identifier supplied by the owner of this node.
  ///
  /// Uniqueness is not enforced by the COM contract.
  String get id;
}
