import { Factory, Group, GroupId, Machine, MachineId, Pipe, PipeId } from "@server/types/core-types";
import { create } from "zustand";
import { immer } from "zustand/middleware/immer";
import { current } from "immer";

/**
 * Type of callback to run after the factory updates.
 */
type PostUpdateCallback = (factory: Factory) => void;

export interface FactoryStore {
  factory: Factory,
  setFactory: PostUpdateCallback,

  getGroupParents: () => GroupParentsMap,

  deletePipes: (pipeIds: PipeId[], callback: PostUpdateCallback) => void,
  addPipes: (pipes: Pipe[], callback: PostUpdateCallback) => void,
  editPipes: (pipes: PipeId[], edits: Partial<Pipe>, callback: PostUpdateCallback) => void,

  editGroups: (groupIds: GroupId[], edits: Partial<Group>, callback: PostUpdateCallback) => void,
  combineGroups: ( sourceGroupIds: GroupId[], targetGroupId: GroupId, callback?: PostUpdateCallback) => void,
  
  editMachines: (machineIds: MachineId[], edits: Partial<Machine>, callback: PostUpdateCallback) => void,
  combineMachines: ( sourceMachineIds: MachineId[], targetMachineId: GroupId, callback?: PostUpdateCallback) => void,
};

const emptyFactory: Factory = {
  machines: {},
  pipes: {},
  groups: {},
  missing: {},
  available: {},
};

export const useFactoryStore = create<FactoryStore>()(
  immer((set, get) => ({
    factory: emptyFactory,
    setFactory: (factory) => set((draft) => { draft.factory = factory }),

    getGroupParents: () => getGroupParents(get().factory),
    
    deletePipes: (pipeIds, callback) => set((draft) => { deletePipes(draft.factory, pipeIds, callback) }),
    addPipes: (pipes, callback) => set((draft) => { addPipes(draft.factory, pipes, callback) }),
    editPipes: (pipeIds, edits, callback) => set((draft) => { editPipes(draft.factory, pipeIds, edits, callback) }),

    editGroups: (groupIds, edits, callback) => set((draft) => { editGroups(draft.factory, groupIds, edits, callback) }),
    combineGroups: (sourceGroupIds, targetGroupId, callback) => set((draft) => { combineGroups(draft.factory, sourceGroupIds, targetGroupId, callback) }),

    editMachines: (machineIds, edits, callback) => set((draft) => { editMachines(draft.factory, machineIds, edits, callback) }),
    combineMachines: ( sourceMachineIds, targetMachineId, callback) => set((draft) => { combineMachines(draft.factory, sourceMachineIds, targetMachineId, callback) }),
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
function getGroupParents(factory: Factory) {
  const groupParents: GroupParentsMap = {};
  for (const machine of Object.values(factory.machines)) {
    for (const groupId of machine.groups) {
      groupParents[groupId] = machine.id;
    }
  }
  return groupParents;
}

function deletePipes(factory: Factory, pipeIds: PipeId[], callback?: PostUpdateCallback) {
  for (let pipeId of pipeIds) {
    delete factory.pipes[pipeId];
  }
  if (callback) callback(factory);
}

function addPipes(
  factory: Factory,
  pipes: Pipe[],
  callback?: PostUpdateCallback
) {
  for (let pipe of pipes) {
    factory.pipes[pipe.id] = pipe;
  }
  if (callback) callback(factory);
}

function editPipes(
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

function deleteMachines(
  factory: Factory,
  machineIds: MachineId[],
  callback?: PostUpdateCallback
) {
  for (let machineId of machineIds) {
    delete factory.machines[machineId];
  }
  if (callback) callback(factory);
}

function editMachines(
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

function deleteGroup(
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

function deleteGroups(
  factory: Factory, 
  groupIds: GroupId[], 
  callback?: PostUpdateCallback
) {
  for (let groupId of groupIds) {
    deleteGroup(factory, groupId, callback);
  }
  if (callback) callback(factory);
}

function editGroups(
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
function addGroups(
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

function canGroupsCombine(source: Group, target: Group) {
  return Boolean(target.fluid) === Boolean(source.fluid);
}

/**
 * Combine one or more source groups with the target group.
 * - Slots from the source will become part of the target.
 * - The source groups will be deleted.
 */
function combineGroups(
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
function combineMachines(
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