import { Pipe, PipeId } from "@server/types/core-types";
import { MachineDelReq, MachineEditReq, PipeAddReq, PipeDelReq, PipeEditReq } from "@server/types/messages";
import { Dispatch, MouseEvent, SetStateAction, useContext } from "react";
import { SendMessage } from "react-use-websocket/dist/lib/types";
import { addEdge, Connection, Edge, Instance, MarkerType, Node, ReactFlowInstance, updateEdge } from "reactflow";
import { v4 as uuidv4 } from "uuid";
import { DropTargetContext } from "./contexts/DropTargetContext";

function onEdgesDelete(edges: Edge[], sendMessage: SendMessage) {
  for (let edge of edges) {
    const pipeDelReq: PipeDelReq = {
      type: "PipeDel",
      reqId: uuidv4(),
      pipeId: edge.id,
    };
    sendMessage(JSON.stringify(pipeDelReq));
  }
}

function onConnect(connection: Connection, sendMessage: SendMessage, setEdges: Dispatch<SetStateAction<Edge[]>>) {
  if (connection.source !== null && connection.target !== null) {
    const pipeId = uuidv4();

    const pipeAddReq: PipeAddReq = {
      type: "PipeAdd",
      reqId: uuidv4(),
      pipe: {
        id: pipeId,
        from: connection.source,
        to: connection.target,
      }
    };
    sendMessage(JSON.stringify(pipeAddReq));

    const newEdge: Edge = {
      source: connection.source,
      target: connection.target,
      id: pipeId,
      type: "pipe",
      markerEnd: {
        type: MarkerType.Arrow,
        width: 20,
        height: 20,
      },
      style: {
        strokeWidth: 2,
      },
    };

    return setEdges((edges) => addEdge(newEdge, edges));
  }
}

function onEdgeUpdate(oldEdge: Edge, newConnection: Connection, sendMessage: SendMessage, setEdges: Dispatch<SetStateAction<Edge[]>>) {
  if (newConnection.source !== null && newConnection.target !== null) {
    const pipeEditReq: PipeEditReq = {
      type: "PipeEdit",
      reqId: uuidv4(),
      pipeId: oldEdge.id,
      edits: {
        from: newConnection.source,
        to: newConnection.target,
      }
    };
    sendMessage(JSON.stringify(pipeEditReq));

    setEdges((els) => updateEdge(oldEdge, newConnection, els, { shouldReplaceId: false }))
  }
}

function onPipeUpdate(pipeId: PipeId, edits: Partial<Pipe>, sendMessage: SendMessage) {
  const pipeEditReq: PipeEditReq = {
    type: "PipeEdit",
    reqId: uuidv4(),
    pipeId: pipeId,
    edits: edits,
  }
  sendMessage(JSON.stringify(pipeEditReq));
}

function nodeIsCompatibleDropTarget(draggedNode: Node, targetNode: Node) {
  return draggedNode.type === "machine" && targetNode.type === "machine";
}

function onNodeDrag(
  mouseEvent: MouseEvent,
  draggedNode: Node,
  getIntersectingNodes: Instance.GetIntersectingNodes<any>,
  reactFlowInstance: (ReactFlowInstance | null),
  setDropTarget: Dispatch<SetStateAction<Node | null>>
) {
  if (reactFlowInstance == null) {
    return;
  }

  // TODO: we should restrict to a single drop target based on the criteria in Issue #9
  const intersections = getIntersectingNodes(draggedNode)
    .filter(node => nodeIsCompatibleDropTarget(draggedNode, node));

  const mousePosition = reactFlowInstance.screenToFlowPosition({
    x: mouseEvent.clientX,
    y: mouseEvent.clientY,
  });

  let closestNode: Node | null = null;
  let closestDistance = Number.MAX_VALUE;
  for (let node of intersections) {
    if (node.positionAbsolute) {
      const dx = node.positionAbsolute.x - mousePosition.x;
      const dy = node.positionAbsolute.y - mousePosition.y;
      const distance = Math.sqrt(dx * dx + dy * dy);

      if (closestDistance > distance) {
        closestDistance = distance;
        closestNode = node;
      }
    }
  }

 setDropTarget(closestNode);
}

function onNodeDragStop(
  mouseEvent: MouseEvent,
  draggedNode: Node,
  dropTarget: Node | null,
  setNodes: Dispatch<SetStateAction<Node[]>>,
  setDropTarget: Dispatch<SetStateAction<Node | null>>,
  sendMessage: SendMessage,
) {
  if (dropTarget) {
    if (draggedNode.type === "machine" && dropTarget.type === "machine") {
      // get the machine's groups and tell cc to add them to the drop target's group list
      sendMessage(JSON.stringify({
        type: "MachineEdit",
        reqId: uuidv4(),
        machineId: draggedNode.id,
        edits: {
          groups: [ ...dropTarget.data.machine.groups, ...draggedNode.data.machine.groups ]
        }
      } as MachineEditReq));

      // tell cc to delete the dragged machine
      sendMessage(JSON.stringify({
        type: "MachineDel",
        reqId: uuidv4(),
        machineId: draggedNode.id,
      } as MachineDelReq));

      // set the parent of the dragged machine's group nodes to the target machine
      setNodes(nodes => nodes
        .filter(node => node.id !== draggedNode.id)
        .map(node => {
          if (node.parentId === draggedNode.id) {
            return {...node, parentId: dropTarget.id}
          }
          return node
        })
      );

      // delete the machine from nodes
    }

    setDropTarget(null);
  }
}

export const GraphUpdateCallbacks = {
  onEdgesDelete: onEdgesDelete,
  onEdgeUpdate: onEdgeUpdate,
  onConnect: onConnect,
  onPipeUpdate: onPipeUpdate,
  onNodeDrag: onNodeDrag,
  onNodeDragStop: onNodeDragStop,
}