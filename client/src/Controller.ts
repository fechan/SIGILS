import { FactoryPutReq } from "@server/types/messages";
import { Factory, PipeId } from "@server/types/core-types";
import { SendMessage } from "react-use-websocket/dist/lib/types";
import { Edge } from "reactflow";
import { v4 as uuidv4 } from "uuid";

function sendFactoryPut(sendMessage: SendMessage, factory: Factory) {
  sendMessage(JSON.stringify({
    reqId: uuidv4(),
    type: "FactoryPut",
    factory: factory,
  } as FactoryPutReq));
}

function deletePipes(
  edges: Edge[],
  deletePipes: (pipeIds: PipeId[], callback: (factory: Factory) => void) => void,
  sendMessage: SendMessage
) {
  deletePipes(
    edges.map(edge => edge.id),
    (factory) => sendFactoryPut(sendMessage, factory)
  );
}

export const Controller = {
  deletePipes: deletePipes,
}