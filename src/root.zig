pub const RedBlackTreeUtils = @import("RedBlackTree/RedBlackTree.zig");
pub const NodeTypes = @import("RedBlackTree/Nodes.zig");

// inititalize a RBTree using the following syntax:
// var mytree: RedBlackTree(<myType>) = undefined;
// mytree.init(<my sentinel value>)
pub const RedBlackTree = RedBlackTreeUtils.RedBlackTree;
pub const RedBlackTreeNode = NodeTypes.RedBlackTreeNode;
pub const RBColor = RedBlackTreeUtils.Color;
pub const NamedRedBlackTreeNode = NodeTypes.NamedRedBlackTreeNode;

pub const ListUtils = @import("Lists/Lists.zig");
pub const LinkedList = ListUtils.LinkedList;
pub const DoubleLinkedList = ListUtils.DoubleLinkedList;
pub const KeyValueDLL = ListUtils.KeyValueDLL;

const DuplexRWHandleUtils = @import("DuplexPipe/duplex_pipe_rw.zig");
pub const create_handle_pair = DuplexRWHandleUtils.create_handle_pair;
pub const DuplexPipeReadWriteHandle = DuplexRWHandleUtils.RWPipeHandle;

pub const DuplexPipeUtils = @import("DuplexPipe/DuplexPipe.zig");
pub const DuplexPipe = DuplexPipeUtils.DuplexPipe;
pub const Queue = DuplexPipeUtils.Queue;
pub const DuplexPipeSide = DuplexPipeUtils.Side;

pub const MapUtils = @import("Map/Map.zig");
pub const Dict = MapUtils.Dict;
pub const HashMap = MapUtils.HashMap;
