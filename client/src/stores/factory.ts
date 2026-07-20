import { Factory, Group, GroupId, Machine, MachineId, Pipe, PipeId } from "@server/types/core-types";
import { create } from "zustand";
import { immer } from "zustand/middleware/immer";

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

  editGroups: (groupsIds: GroupId[], edits: Partial<Group>, callback: PostUpdateCallback) => void,
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
    const groupIndex = machine.groups.indexOf(machineId);
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
  callback?: PostUpdateCallback,
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
  callback?: PostUpdateCallback,
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