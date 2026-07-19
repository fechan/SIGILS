import { FactoryPutReq } from "@server/types/messages";
import { Factory, Pipe } from "@server/types/core-types";
import { SendMessage } from "react-use-websocket/dist/lib/types";
import { Edge } from "reactflow";
import { v4 as uuidv4 } from "uuid";
import { FactoryStore } from "./stores/factory";

function sendFactoryPut(sendMessage: SendMessage, factory: Factory) {
  sendMessage(JSON.stringify({
    reqId: uuidv4(),
    type: "FactoryPut",
    factory: factory,
  } as FactoryPutReq));
}

export function deletePipes(
  edges: Edge[],
  deletePipes: FactoryStore['deletePipes'],
  sendMessage: SendMessage
) {
  deletePipes(
    edges.map(edge => edge.id),
    (factory) => sendFactoryPut(sendMessage, factory)
  );
}

export function addPipes(
  pipes: Pipe[],
  addPipes: FactoryStore['addPipes'],
  sendMessage: SendMessage
) {
  addPipes(
    pipes,
    (factory) => sendFactoryPut(sendMessage, factory)
  );
}