import { FactoryPutReq } from "@server/types/messages";
import { Factory, Pipe } from "@server/types/core-types";
import { SendMessage } from "react-use-websocket/dist/lib/types";
import { Edge } from "reactflow";
import { v4 as uuidv4 } from "uuid";
import { FactoryStore } from "./stores/factory";

export class Controller {
  sendMessage: SendMessage; 

  constructor(sendMessage: SendMessage) {
    this.sendMessage = sendMessage;
  }

  postUpdate(factory: Factory) {
    this.sendMessage(JSON.stringify({
      reqId: uuidv4(),
      type: "FactoryPut",
      factory: factory,
    } as FactoryPutReq));
  }

  deletePipes(
    edges: Edge[],
    deletePipes: FactoryStore['deletePipes'],
  ) {
    deletePipes(
      edges.map(edge => edge.id),
      (factory) => this.postUpdate(factory)
    );
  }

  addPipes(
    pipes: Pipe[],
    addPipes: FactoryStore['addPipes'],
  ) {
    addPipes(
      pipes,
      (factory) => this.postUpdate(factory)
    );
  }
}
