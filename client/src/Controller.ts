import { FactoryPutReq } from "@server/types/messages";
import { Factory, Group, GroupId, Machine, MachineId, Peripheral, PeriphId, Pipe, PipeId } from "@server/types/core-types";
import { SendMessage } from "react-use-websocket/dist/lib/types";
import { Connection, Edge, Node } from "reactflow";
import { v4 as uuidv4 } from "uuid";
import { FactoryStore } from "./stores/factory";
import { ItemSlotDragData } from "./components/ItemSlot";
import { PeripheralBadgeDragData } from "./components/PeripheralBadge";
import { ConnectedPeriphsStore } from "./stores/connectedPeriphs";

export interface XYPosition {
  x: number;
  y: number;
}

export class Controller {
  sendMessage: SendMessage; 
  factoryStore: FactoryStore;
  connectedPeriphsStore: ConnectedPeriphsStore;

  constructor(sendMessage: SendMessage, factoryStore: FactoryStore, connectedPeriphsStore: ConnectedPeriphsStore) {
    this.sendMessage = sendMessage;
    this.factoryStore = factoryStore;
    this.connectedPeriphsStore = connectedPeriphsStore;
  }

  // TODO: it probably makes more sense to send the message AFTER React has
  // picked up on the factory store's changes, since we're not waiting on any
  // response data from the ComputerCraft side anymore
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

  splitPeripheralFromMachine(peripheralData: PeripheralBadgeDragData, intersections: Node[], initialPosition: XYPosition) {
    const { periphId, oldMachineId } = peripheralData;
    
    // don't do anything if dragging to the same machine
    intersections = intersections.filter(node => node.id === oldMachineId);
    if (intersections.length > 0) {
      return;
    }

    // don't do anything if there's only one peripheral in the machine
    const factory = this.factoryStore.factory;
    const peripheralIds = new Set<string>();
    for (let groupId of factory.machines[oldMachineId].groups) {
      const group = factory.groups[groupId];
      for (let slot of group.slots) {
        peripheralIds.add(slot.periphId);
      }
    }
    if (peripheralIds.size === 1) {
      return;
    }

    this.factoryStore.splitPeripheralFromMachine(
      periphId,
      oldMachineId,
      initialPosition.x,
      initialPosition.y,
      (factory) => this.postUpdate(factory)
    );
  }

  addPeripheralAsMachine(periphId: PeriphId, periph: Peripheral, initialOptions?: Partial<Machine>) {
    const periphsInFactory = this.factoryStore.getPeripheralNames();
    const availablePeriphs = this.connectedPeriphsStore.getAvailable(periphsInFactory);
    if (!availablePeriphs.has(periphId)) {
      throw Error("Attempted to add a peripheral to the factory that is either disconnected or already in the factory!");
    }

    this.factoryStore.addPeripheralAsMachine(
      periphId,
      periph,
      initialOptions,
      (factory) => this.postUpdate(factory)
    );
  }

  deletePeripheralFromFactory(periphId: PeriphId) {
    const periphsInFactory = this.factoryStore.getPeripheralNames();
    const missingPeriphs = this.connectedPeriphsStore.getMissing(periphsInFactory);
    if (!missingPeriphs.has(periphId)) {
      throw Error("Attempted to delete a peripheral from the factory that is still connected!");
    }

    this.factoryStore.deletePeripheralFromFactory(
      periphId,
      (factory) => this.postUpdate(factory)
    );
  }
}
