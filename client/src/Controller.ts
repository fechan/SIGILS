import { FactoryPutReq } from "@server/types/messages";
import { Factory, Group, GroupId, Machine, MachineId, Pipe, PipeId } from "@server/types/core-types";
import { SendMessage } from "react-use-websocket/dist/lib/types";
import { Connection, Edge } from "reactflow";
import { v4 as uuidv4 } from "uuid";
import { FactoryStore } from "./stores/factory";

export class Controller {
  sendMessage: SendMessage; 
  factoryStore: FactoryStore

  constructor(sendMessage: SendMessage, factoryStore: FactoryStore) {
    this.sendMessage = sendMessage;
    this.factoryStore = factoryStore;
  }

  postUpdate(factory: Factory) {
    this.sendMessage(JSON.stringify({
      reqId: uuidv4(),
      type: "FactoryPut",
      factory: factory,
    } as FactoryPutReq));
  }

  deletePipes(edges: Edge[]) {
    this.factoryStore.deletePipes(
      edges.map(edge => edge.id),
      (factory) => this.postUpdate(factory)
    );
  }

  addPipes(pipes: Pipe[]) {
    this.factoryStore.addPipes(
      pipes,
      (factory) => this.postUpdate(factory)
    );
  }

  editPipes(pipeIds: PipeId[], edits: Partial<Pipe>) {
    this.factoryStore.editPipes(
      pipeIds,
      edits,
      (factory) => this.postUpdate(factory)
    );
  }

  editPipeConnection(edge: Edge, newConnection: Connection) {
    if (newConnection.source === null && newConnection.target === null) {
      return;
    }

    const edits: Partial<Pipe> = {
      from: newConnection.source!,
      to: newConnection.target!,
    };

    this.factoryStore.editPipes(
      [edge.id],
      edits,
      (factory) => this.postUpdate(factory)
    );
  }

  editGroups(groupIds: GroupId[], edits: Partial<Group>) {
    this.factoryStore.editGroups(
      groupIds,
      edits,
      (factory) => this.postUpdate(factory)
    );
  }

  editMachines(machineIds: MachineId[], edits: Partial<Machine>) {
    this.factoryStore.editMachines(
      machineIds,
      edits,
      (factory) => this.postUpdate(factory)
    );
  }
}
