import { Factory, Group, GroupId, Machine, MachineId, Peripheral, PeriphId, Pipe, PipeId, Slot } from '@server/types/core-types';
import { create } from 'zustand';
import { immer } from 'zustand/middleware/immer';
import { v4 as uuidv4 } from 'uuid';

/**
 * Type of callback to run after the factory updates.
 */
type PostUpdateCallback = (factory: Factory) => void;

export interface FactoryStore {
  factory: Factory,
  setFactory: PostUpdateCallback,

  getGroupParents: () => GroupParentsMap,
  getPeripheralNames: () => Set<PeriphId>,

  deletePipes: (pipeIds: PipeId[], callback?: PostUpdateCallback) => void,
  addPipes: (pipes: Pipe[], callback?: PostUpdateCallback) => void,
  editPipes: (pipes: PipeId[], edits: Partial<Pipe>, callback?: PostUpdateCallback) => void,

  addGroups: (groups: Group[], machineId?: MachineId, callback?: PostUpdateCallback) => void,
  editGroups: (groupIds: GroupId[], edits: Partial<Group>, callback?: PostUpdateCallback) => void,
  combineGroups: (sourceGroupIds: GroupId[], targetGroupId: GroupId, callback?: PostUpdateCallback) => void,
  splitSlotFromGroup: (
    slot: Slot,
    groupId: GroupId,
    machineId: MachineId,
    newGroupX: number,
    newGroupY: number,
    callback?: PostUpdateCallback,
  ) => void,
  
  addMachines: (machines: Machine[], callback?: PostUpdateCallback) => void,
  editMachines: (machineIds: MachineId[], edits: Partial<Machine>, callback?: PostUpdateCallback) => void,
  combineMachines: ( sourceMachineIds: MachineId[], targetMachineId: GroupId, callback?: PostUpdateCallback) => void,
  splitPeripheralFromMachine: (
    periphId: PeriphId,
    machineId: MachineId,
    newMachineX: number,
    newMachineY: number,
    callback?: PostUpdateCallback
  ) => void;
  addPeripheralAsMachine: (
    periphId: PeriphId,
    initialOptions: Partial<Machine>,
    callback?: PostUpdateCallback) => void,
};

const emptyFactory: Factory = {
  machines: {},
  pipes: {},
  groups: {},
};

export const useFactoryStore = create<FactoryStore>()(
  immer((set, get) => ({
    factory: emptyFactory,
    setFactory: (factory) => set((draft) => { draft.factory = factory }),

    getGroupParents: () => getGroupParents(get().factory),
    getPeripheralNames: () => getPeripheralNames(get().factory),
    
    deletePipes: (pipeIds, callback) => set((draft) => { deletePipes(draft.factory, pipeIds, callback) }),
    addPipes: (pipes, callback) => set((draft) => { addPipes(draft.factory, pipes, callback) }),
    editPipes: (pipeIds, edits, callback) => set((draft) => { editPipes(draft.factory, pipeIds, edits, callback) }),

    addGroups: (groups, machineId, callback) => set((draft) => { addGroups(draft.factory, groups, machineId, callback) }),
    editGroups: (groupIds, edits, callback) => set((draft) => { editGroups(draft.factory, groupIds, edits, callback) }),
    combineGroups: (sourceGroupIds, targetGroupId, callback) => set((draft) => { combineGroups(draft.factory, sourceGroupIds, targetGroupId, callback) }),
    splitSlotFromGroup: (slot, groupId, machineId, newGroupX, newGroupY, callback) => set((draft) => { splitSlotFromGroup(draft.factory, slot, groupId, machineId, newGroupX, newGroupY, callback) }),

    addMachines: (machines, callback) => set((draft) => { addMachines(draft.factory, machines, callback) }),
    editMachines: (machineIds, edits, callback) => set((draft) => { editMachines(draft.factory, machineIds, edits, callback) }),
    combineMachines: (sourceMachineIds, targetMachineId, callback) => set((draft) => { combineMachines(draft.factory, sourceMachineIds, targetMachineId, callback) }),
    splitPeripheralFromMachine: (periphId, machineId, newMachineX, newMachineY, callback) => set((draft) => { splitPeripheralFromMachine(draft.factory, periphId, machineId, newMachineX, newMachineY, callback) }),
    addPeripheralAsMachine: (periphId, initialOptions, callback) => set((draft) => { addPeripheralAsMachine(draft.factory, periphId, initialOptions, callback) }),
  }))
);

export interface GroupParentsMap {
  [key: GroupId]: MachineId
};

/**
 * Get a map from group IDs to their parent machine ID
 * @param factory Factory the groups and machines are in
 * @returns Map from group IDs to parent machine IDs
 */
export function getGroupParents(factory: Factory) {
  const groupParents: GroupParentsMap = {};
  for (const machine of Object.values(factory.machines)) {
    for (const groupId of machine.groups) {
      groupParents[groupId] = machine.id;
    }
  }
  return groupParents;
}

export function getPeripheralNames(factory: Factory) {
  const periphNames = new Set<PeriphId>();

  for (const group of Object.values(factory.groups)) {
    for (const slot of group.slots) {
      periphNames.add(slot.periphId);
    }
  }

  return periphNames;
}

export function deletePipes(factory: Factory, pipeIds: PipeId[], callback?: PostUpdateCallback) {
  for (let pipeId of pipeIds) {
    delete factory.pipes[pipeId];
  }
  if (callback) callback(factory);
}

export function addPipes(
  factory: Factory,
  pipes: Pipe[],
  callback?: PostUpdateCallback
) {
  for (let pipe of pipes) {
    factory.pipes[pipe.id] = pipe;
  }
  if (callback) callback(factory);
}

export function editPipes(
  factory: Factory,
  pipeIds: PipeId[],
  edits: Partial<Machine>,
  callback?: PostUpdateCallback
) {
  for (let pipeId of pipeIds) {
    factory.pipes[pipeId] = { ...(factory.pipes[pipeId]), ...edits};
  }
  if (callback) callback(factory);
}

export function addMachines(
  factory: Factory,
  machines: Machine[],
  callback?: PostUpdateCallback
) {
  for (const machine of machines) {
    factory.machines[machine.id] = machine;
  }
  if (callback) callback(factory);
}

export function deleteMachines(
  factory: Factory,
  machineIds: MachineId[],
  callback?: PostUpdateCallback
) {
  for (let machineId of machineIds) {
    delete factory.machines[machineId];
  }
  if (callback) callback(factory);
}

export function editMachines(
  factory: Factory,
  machineIds: MachineId[],
  edits: Partial<Machine>,
  callback?: PostUpdateCallback
) {
  for (let machineId of machineIds) {
    factory.machines[machineId] = { ...(factory.machines[machineId]), ...edits};
  }
  if (callback) callback(factory);
}

export function deleteGroup(
  factory: Factory, 
  groupId: GroupId, 
  callback?: PostUpdateCallback
) {
  delete factory.groups[groupId];

  // delete all pipes that have this group at either end
  for (let [pipeId, pipe] of Object.entries(factory.pipes)) {
    if (pipe.from === groupId || pipe.to === groupId) {
      deletePipes(factory, [pipeId]);
    }
  }

  // find the machine that had the group in it and remove the group from it
  for (let [machineId, machine] of Object.entries(factory.machines)) {
    const groupIndex = machine.groups.indexOf(groupId);
    if (groupIndex > -1) {
      machine.groups.splice(groupIndex);

      if (machine.groups.length === 0) {
        deleteMachines(factory, [machineId]);
      }

      break
    }
  }

  if (callback) callback(factory);
}

export function deleteGroups(
  factory: Factory, 
  groupIds: GroupId[], 
  callback?: PostUpdateCallback
) {
  for (let groupId of groupIds) {
    deleteGroup(factory, groupId, callback);
  }
  if (callback) callback(factory);
}

export function editGroups(
  factory: Factory,
  groupIds: GroupId[],
  edits: Partial<Group>,
  callback?: PostUpdateCallback
) {
  for (let groupId of groupIds) {
    factory.groups[groupId] = { ...(factory.groups[groupId]), ...edits};
  }
  if (callback) callback(factory);
}

/**
 * Add groups to the factory, optionally adding them directly to a machine.
 * @param factory Factory to add to
 * @param groups New groups to add
 * @param machineId Machine to add the group to. If provided, all new groups will be added to the machine's group list.
 * @param callback Callback to run after the factory is updated.
 */
export function addGroups(
  factory: Factory,
  groups: Group[],
  machineId?: MachineId,
  callback?: PostUpdateCallback
) {
  for (let group of groups) {
    factory.groups[group.id] = group;
  }

  if (machineId) {
    let groupIds = groups.map(group => group.id);
    factory.machines[machineId].groups.push(...groupIds);
  }

  if (callback) callback(factory);
}

export function canGroupsCombine(source: Group, target: Group) {
  return Boolean(target.fluid) === Boolean(source.fluid);
}

/**
 * Combine one or more source groups with the target group.
 * - Slots from the source will become part of the target.
 * - The source groups will be deleted.
 */
export function combineGroups(
  factory: Factory,
  sourceGroupIds: GroupId[],
  targetGroupId: GroupId,
  callback?: PostUpdateCallback
) {
  // find the groups to be combined
  const targetGroup = factory.groups[targetGroupId];

  let sourceGroups = (sourceGroupIds
    .map(id => factory.groups[id])
    .filter(sourceGroup => canGroupsCombine(sourceGroup, targetGroup))); // only combine fluid groups into fluid groups and vice versa

  // set the target's slots to be the union of all their slots
  const combinedSlots = ([targetGroup, ...sourceGroups]
    .map(group => group.slots)
    .flat());
  targetGroup.slots = combinedSlots;

  // delete the source groups
  deleteGroups(factory, sourceGroups.map(group => group.id));

  if (callback) callback(factory);
}

/**
 * Combine one or more source machines into a target machine.
 * - Groups from the source machines will be moved into the target
 *   - Groups that are named the same across machines will be combined
 * - The source machines will be deleted
 */
export function combineMachines(
  factory: Factory,
  sourceMachineIds: MachineId[],
  targetMachineId: MachineId,
  callback?: PostUpdateCallback,
) {
  // sort groups into should combine/should not combine
  const namedGroups: {[nick: string]: GroupId[]} = {}; // named groups with the same nickname will be combined into the first group of that name encountered
  const namedFluidGroups: {[nick: string]: GroupId[]} = {};
  const unnamedGroups: GroupId[] = []; // unnamed groups will just be added to the target without changing its slots

  for (let machineId of [targetMachineId].concat(sourceMachineIds)) {
    for (let groupId of factory.machines[machineId].groups) {
      const group = factory.groups[groupId];

      if (!group.nickname) {
        unnamedGroups.push(groupId);
        continue;
      }

      if (group.fluid) {
        if (!(group.nickname in namedFluidGroups)) {
          namedFluidGroups[group.nickname] = [];
        }
      } else {
        if (!(group.nickname in namedGroups)) {
          namedGroups[group.nickname] = [];
        }
      }

      if (group.fluid) {
        namedFluidGroups[group.nickname].push(groupId);
      } else {
        namedGroups[group.nickname].push(groupId);
      }
    }
  }

  // combine like-named source groups into the target groups
  const finalNamedGroups: GroupId[] = []; // named groups that have been combined
  for (const groupIds of Object.values(namedGroups)) {
    if (groupIds.length > 1) {
      combineGroups(factory, groupIds.slice(1), groupIds[0]);
    }
    finalNamedGroups.push(groupIds[0]);
  }

  const finalNamedFluidGroups: GroupId[] = []; // named fluid groups that have been combined
  for (const groupIds of Object.values(namedFluidGroups)) {
    if (groupIds.length > 1) {
      combineGroups(factory, groupIds.slice(1), groupIds[0])
    }
    finalNamedFluidGroups.push(groupIds[0]);
  }

  factory.machines[targetMachineId].groups = [
    ...finalNamedGroups,
    ...finalNamedFluidGroups,
    ...unnamedGroups
  ];

  // delete the source machines
  deleteMachines(factory, sourceMachineIds);

  if (callback) callback(factory);
}

export function splitSlotFromGroup(
  factory: Factory,
  slot: Slot,
  groupId: GroupId,
  machineId: MachineId,
  newGroupX: number,
  newGroupY: number,
  callback?: PostUpdateCallback
) {
  const oldGroup = factory.groups[groupId];

  // make a new group containing the slot
  const newGroup = {
    id: uuidv4(),
    nickname: oldGroup.nickname,
    slots: [slot],
    x: newGroupX,
    y: newGroupY,
    fluid: oldGroup.fluid,
  };
  addGroups(factory, [newGroup], machineId);

  // delete the slot from the old group
  const oldGroupSlots = oldGroup.slots;
  const oldGroupSlotsUpdated = oldGroupSlots.filter((oldSlot: Slot) => oldSlot.periphId !== slot.periphId || oldSlot.slot !== slot.slot);
  editGroups(factory, [oldGroup.id], { slots: oldGroupSlotsUpdated });

  if (callback) callback(factory);
}

export function splitPeripheralFromMachine(
  factory: Factory,
  periphId: PeriphId,
  machineId: MachineId,
  newMachineX: number,
  newMachineY: number,
  callback?: PostUpdateCallback
) {
  // create a machine for the split peripheral
  const newMachineId = uuidv4();
  addMachines(factory, [{
    id: newMachineId,
    nickname: periphId,
    groups: [],
    x: newMachineX,
    y: newMachineY,
  }]);

  for (let groupId of factory.machines[machineId].groups) {
    const oldGroup = factory.groups[groupId];
    const slotsFromPeripheral = oldGroup.slots.filter(slot => slot.periphId === periphId);
    if (slotsFromPeripheral.length > 0) {
      // make new group with all slots from this peripheral that were in the old group
      addGroups(factory, [{
        id: uuidv4(),
        nickname: oldGroup.nickname,
        slots: slotsFromPeripheral,
        fluid: oldGroup.fluid,
      }], newMachineId);

      // remove slots from this peripheral from the old group
      const oldGroupUpdatedSlots = oldGroup.slots.filter(slot => slot.periphId !== periphId)
      if (oldGroupUpdatedSlots.length > 0) {
        editGroups(factory, [oldGroup.id], { slots: oldGroupUpdatedSlots });
      } else {
        deleteGroup(factory, oldGroup.id);
      }
    }
  } 

  if (callback) callback(factory);
}

function initializeMachine(periphId: PeriphId, periph: Peripheral) {
  // TODO: move this function to a separate module

  const groups: Group[] = [];

  // initialize inventory slots
  if (periph.size) {
    for (let i=1; i <= periph.size; i++) {
      groups.push({
        'id': `${periphId}:g${i}`,
        'slots': [{
          'periphId': periphId,
          'slot': i,
        }],
      } as Group);
    }
  }

  // initialize fluid tank
  if (periph.fluidTank) {
    groups.push({
      'id': periphId + 'fluid',
      'nickname': 'Fluid tank',
      'fluid': true,
      'slots': [{
        periphId: periphId,
      }],
    } as Group)
  }

  const machine: Machine = {
    'id': periphId,
    'groups': groups.map(group => group.id),
  };

  return { machine, groups }
}

export function addPeripheralAsMachine(
  factory: Factory,
  periphId: PeriphId,
  periph: Peripheral,
  initialOptions: Partial<Machine>,
  callback?: PostUpdateCallback
) {
  let { machine, groups } = initializeMachine(periphId, periph);
  machine = { ...initialOptions, ...machine };

  addGroups(factory, groups);
  addMachines(factory, [machine]);

  if (callback) callback(factory);
}