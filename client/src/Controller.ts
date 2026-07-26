import { FactoryPutReq } from "@server/types/messages";
import { Factory, Group, GroupId, Machine, MachineId, Pipe, PipeId } from "@server/types/core-types";
import { SendMessage } from "react-use-websocket/dist/lib/types";
import { Connection, Edge, Node } from "reactflow";
import { v4 as uuidv4 } from "uuid";
import { FactoryStore } from "./stores/factory";
import { ItemSlotDragData } from "./components/ItemSlot";

export interface XYPosition {
  x: number;
  y: number;
}

export class Controller {
  sendMessage: SendMessage; 
  factoryStore: FactoryStore

  constructor(sendMessage: SendMessage, factoryStore: FactoryStore) {
    this.sendMessage = sendMessage;
    this.factoryStore = factoryStore;
  }

  // TODO: wouldn't it make more sense for the model to return the factory draft
  // and the controller call this method directly rather than having
  // the model run a callback?
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

  combineGroups(sourceGroupIds: GroupId[], targetGroupId: GroupId) {
    this.factoryStore.combineGroups(
      sourceGroupIds,
      targetGroupId,
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

  combineMachines(sourceMachineIds: MachineId[], targetMachineId: MachineId) {
    this.factoryStore.combineMachines(
      sourceMachineIds,
      targetMachineId,
      (factory) => this.postUpdate(factory)
    );
  }

  splitSlotFromGroup(slotData: ItemSlotDragData, intersections: Node[], initialPosition: XYPosition) {
    const { slot, machineId, oldGroupId } = slotData;
    const factory = this.factoryStore.factory;

    // check if we're over a machine node of the same ID as machineId
    intersections = intersections.filter(node => node.id === machineId);

    // check if taking the slot out will cause the old group to be empty
    const oldGroup = factory.groups[oldGroupId];
    const oldGroupSlots = oldGroup.slots;
    const oldGroupWillBeEmpty = oldGroupSlots.length === 1;

    if (intersections.length <= 0 || oldGroupWillBeEmpty) {
      return;
    }

    this.factoryStore.splitSlotFromGroup(
      slot,
      oldGroupId,
      machineId,
      initialPosition.x,
      initialPosition.y,
      (factory) => this.postUpdate(factory)
    );
  }
}
