import { Factory, GroupId, MachineId, PipeId } from "@server/types/core-types";
import { create } from "zustand";
import { immer } from "zustand/middleware/immer";

export interface FactoryStore {
  /** Factory object */
  factory: Factory,
  getGroupParents: () => GroupParentsMap,
  setFactory: (factory: Factory) => void,
  deletePipes: (pipeIds: PipeId[], callback: (factory: Factory) => void) => void,
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
    getGroupParents: () => getGroupParents(get().factory),
    setFactory: (factory) => set((draft) => { draft.factory = factory }),
    deletePipes: (pipeIds, callback) => set((draft) => { deletePipes(draft.factory, pipeIds, callback) }),
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

function deletePipes(factory: Factory, pipeIds: PipeId[], callback: (factory: Factory) => void) {
  for (let pipeId of pipeIds) {
    delete factory.pipes[pipeId];
  }
  callback(factory);
}