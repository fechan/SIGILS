import { Factory, GroupId, MachineId, PipeId } from "@server/types/core-types";
import { create } from "zustand";
import { immer } from "zustand/middleware/immer";

interface FactoryStore {
  /** Factory object */
  factory: Factory,
  getGroupParents: () => GroupParentsMap,
  setFactory: (factory: Factory) => void,
  deletePipe: (pipeId: PipeId) => void,
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
    setFactory: (factory: Factory) => set((draft) => {draft.factory = factory}),
    deletePipe: (pipeId: PipeId)   => set((draft) => {deletePipe(draft.factory, pipeId)}),
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

function deletePipe(factory: Factory, pipeId: PipeId) {
  delete factory.pipes[pipeId];
}