import 'com_group.dart';
import 'com_node.dart';

/// Lazily visits [root] and its descendants in pre-order.
///
/// Each group is visited before its children. Nodes that are not groups are
/// leaves in this initial COM model.
Iterable<ComNode> traverseComPreOrder(ComNode root) sync* {
  yield root;

  if (root is ComGroup) {
    for (final child in root.children) {
      yield* traverseComPreOrder(child);
    }
  }
}
