import 'com_node.dart';

/// A COM node that contains an ordered, immutable snapshot of child nodes.
///
/// The collection is copied and cannot be changed through [children], but
/// child objects themselves are not deep-copied.
final class ComGroup implements ComNode {
  @override
  final String id;

  /// The group's ordered child nodes.
  final List<ComNode> children;

  ComGroup({
    required this.id,
    Iterable<ComNode> children = const <ComNode>[],
  }) : children = List<ComNode>.unmodifiable(children);

  /// Returns a new group snapshot with the provided fields replaced.
  ComGroup copyWith({
    String? id,
    Iterable<ComNode>? children,
  }) {
    return ComGroup(
      id: id ?? this.id,
      children: children ?? this.children,
    );
  }
}
