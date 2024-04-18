import useWebSocket, { ReadyState } from "react-use-websocket";
import { ConfirmationResponse, FactoryGetReq, FactoryGetRes, FailResponse, Message, PipeAddReq, SuccessResponse } from "@server/types/messages";
import { v4 as uuidv4 } from "uuid";

import type { Node, NodeDragHandler, OnConnect, OnEdgesDelete, OnEdgeUpdateFunc, OnInit, ReactFlowInstance } from "reactflow";

import { MouseEvent, useCallback, useEffect, useState } from "react";
import {
  Background,
  Controls,
  MiniMap,
  ReactFlow,
  addEdge,
  useNodesState,
  useEdgesState,
  Panel,
  useReactFlow,
  useStore,
} from "reactflow";

import "reactflow/dist/style.css";

import { Factory } from "@server/types/core-types";
import { nodeTypes, getNodesForFactory } from "./nodes";
import { edgeTypes, getEdgesForFactory } from "./edges";

import { NewSessionModal } from "./components/NewSessionModal";
import { GraphUpdateCallbacks } from "./GraphUpdateCallbacks";
import { EdgeOptions } from "./components/EdgeOptions";
import { DropTargetContext } from "./contexts/DropTargetContext";

export default function App() {
  const [ socketUrl, setSocketUrl ] = useState("ws://localhost:3000");
  const { sendMessage, lastMessage, readyState } = useWebSocket(socketUrl, {
    shouldReconnect: () => true,
    reconnectAttempts: 10,
    reconnectInterval: 3000,
  });
  const [ showNewSessionModal, setShowNewSessionModal ] = useState(true);

  const { getIntersectingNodes } = useReactFlow();
  const [ factory, setFactory ] = useState({pipes: {}, machines: {}, groups: {}} as Factory);
  const [ nodes, setNodes, onNodesChange ] = useNodesState([]);
  const [ edges, setEdges, onEdgesChange ] = useEdgesState([]);
  const [ reactFlowInstance, setReactFlowInstance ] = useState(null as (ReactFlowInstance<any, any> | null));
  const [ dropTarget, setDropTarget ] = useState(null as (Node | null));

  /**
   * Handlers for React Flow events
   */
  const onConnect: OnConnect = useCallback(
    (connection) => GraphUpdateCallbacks.onConnect(connection, sendMessage, setEdges),
    [setEdges]
  );

  const onEdgesDelete: OnEdgesDelete = useCallback(
    (edges) => GraphUpdateCallbacks.onEdgesDelete(edges, sendMessage),
    [sendMessage]
  );

  const onEdgeUpdate: OnEdgeUpdateFunc = useCallback(
    (oldEdge, newConnection) => GraphUpdateCallbacks.onEdgeUpdate(oldEdge, newConnection, sendMessage, setEdges),
    [sendMessage, setEdges]
  );

  const onNodeDrag: NodeDragHandler = useCallback(
    (mouseEvent: MouseEvent, node: Node) => GraphUpdateCallbacks.onNodeDrag(mouseEvent, node, getIntersectingNodes, reactFlowInstance, setDropTarget),
    [getIntersectingNodes, reactFlowInstance, setDropTarget]
  );

  const onNodeDragStop: NodeDragHandler = useCallback(
    (mouseEvent: MouseEvent, node: Node) => GraphUpdateCallbacks.onNodeDragStop(mouseEvent, node, dropTarget, setNodes, setDropTarget, sendMessage),
    [setNodes, setDropTarget, dropTarget, sendMessage]
  );

  /**
   * End handlers for React Flow events
   */

  useEffect(() => {
    setNodes(getNodesForFactory(factory));
    setEdges(getEdgesForFactory(factory));
  }, [factory]);

  useEffect(() => {
    if (readyState === ReadyState.CLOSED)
      setShowNewSessionModal(true)
  }, [readyState])

  useEffect(() => {
    if (lastMessage !== null && typeof lastMessage.data === "string") {
      const message: Message = JSON.parse(lastMessage.data as string);
      
      if (message.type === "ConfirmationResponse") {
        if ((message as ConfirmationResponse).ok) {
          const successRes = message as SuccessResponse;

          if (successRes.respondingTo === "SessionJoin") {
            setShowNewSessionModal(false);
            const factoryGetReq: FactoryGetReq = {
              type: "FactoryGet",
              reqId: uuidv4(),
            };
            sendMessage(JSON.stringify(factoryGetReq));
            return;
          }

          if (successRes.respondingTo === "FactoryGet") {
            const factoryGetRes = message as FactoryGetRes;
            setFactory(factoryGetRes.factory);
            return;
          }
        } else {
          const failRes = message as FailResponse;

          if (failRes.respondingTo === "SessionJoin") {
            alert("Error joining session: " + (failRes.message || "Unknown reason"));
          }
        }
      }

    }
  }, [lastMessage]);

  return (
    <div className="w-full h-full">
      { showNewSessionModal && <NewSessionModal sendMessage={ sendMessage } /> }

      <DropTargetContext.Provider value={{ dropTarget, setDropTarget }}>
        <ReactFlow
          nodes={nodes}
          nodeTypes={nodeTypes}
          onNodesChange={onNodesChange}
          edges={edges}
          edgeTypes={edgeTypes}
          onEdgesChange={onEdgesChange}
          onEdgesDelete={onEdgesDelete}
          onEdgeUpdate={onEdgeUpdate}
          onConnect={onConnect}
          onInit={setReactFlowInstance}
          onNodeDrag={onNodeDrag}
          onNodeDragStop={onNodeDragStop}
          fitView
        >
          <Panel position="top-right">
            <EdgeOptions
              sendMessage={ sendMessage }
              setEdges={ setEdges }
             />
          </Panel>
          <Background />
          <MiniMap />
          <Controls />
        </ReactFlow>
      </DropTargetContext.Provider>
    </div>
  );
}
